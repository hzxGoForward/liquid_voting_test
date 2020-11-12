pragma solidity >=0.4.21 <0.6.0;
import "./AddressArray.sol";
import "./LinkCutTree.sol";

contract LiquidDemocracy{

  using AddressArray for address[];

  address public owner;

  mapping (address => uint) public vote_weight;
  mapping (address => address) public v_to_parent;
  mapping (address => address[]) public v_to_children;
  uint public voter_count;

  // add by hzx
  LinkCutTree lct;

  event Delegate(address from, address to, uint height);
  event Undelegate(uint32 from, uint32 to);
  event SetWeight(address addr, uint weight, uint height);
  event CreateVote(address addr, uint height);
  //   event ShowNode(address addr, uint32 num, uint32 father, uint32 lc, uint32 rc);
  event ShowNode(address addr, uint32 num, uint32 fatherNum);
  event ReDelegate(uint32 node, uint32 oldDelegate, uint32 newDelegate);
  constructor() public{
    owner = msg.sender;
    voter_count = 0;
    lct = new LinkCutTree();
  }

  modifier isOwner{
    if(msg.sender == owner) _;
  }

  function setWeight(address addr, uint weight) public isOwner{
    require(weight > 0);
    require(addr != address(0x0));
    vote_weight[addr] = weight;
    voter_count ++;

    // add a new address.
    lct.getAddrNum(addr);
    // emit SetWeight(addr, weight, block.number);
  }

  function check_circle(address _from, address _to) internal returns(bool){
    address fa_from = v_to_parent[_from];
    uint32 num_from = lct.getAddrNum(_from);
    uint32 num_to = lct.getAddrNum(_to);
    
    // 先尝试切断_from的delegatee
    lct.access(num_from);
    if(fa_from != address(0x0)){
        lct.cut(_from, fa_from);
        address[] storage children = v_to_children[fa_from];
        children.remove(_from);
        v_to_parent[_from] = address(0x0);
    }
    // 将根节点到num_to的路径放入splay树
     lct.access(num_to);
    
    // 检测_from是否和_to存在路径，如果存在，则说明有环
    bool has_circle = false;
    if(lct.isConnected(_from, _to)){
        has_circle = true;
    }
    // 最后恢复_from的delegatee
    if(fa_from != address(0x0)){
        lct.link(_from, fa_from);
        v_to_parent[_from] = fa_from;
        v_to_children[fa_from].push(_from);
    }
    
    return has_circle;
  }


  function delegate(address _to) public {
    require(_to != msg.sender, "cannot be self");
    require(vote_weight[msg.sender] != 0, "no sender");
    require(vote_weight[_to] != 0, "no _to");
    // 避免重复代理
    address old = v_to_parent[msg.sender];
    require(old != _to, "repeat delegate");

    // 检测是否是环路代理
    bool has_circle = check_circle(msg.sender, _to);
    require(!has_circle, "can not be circle delegate");

    uint32 num_old = 0;
    if(old != address(0x0)){
      address[] storage children = v_to_children[old];
      children.remove(msg.sender);
      num_old = lct.getAddrNum(old);
      v_to_parent[msg.sender] = address(0x0);
      lct.cut(msg.sender, old);
    }
    // 更新新的代理
    lct.link(msg.sender, _to);
    v_to_parent[msg.sender] = _to;
    v_to_children[_to].push(msg.sender);
    

    uint32 num_sender = lct.getAddrNum(msg.sender);
    uint32 num_to = lct.getAddrNum(_to);
    uint32 sender_fa = num_to;

    address fa_to_addr = v_to_parent[_to];
    uint32 fa_to = 0;
    if(v_to_parent[_to] != address(0x0))
        fa_to = lct.getAddrNum(v_to_parent[_to]);
    uint32 to_lch = lct.getChild(0, num_to);
    uint32 to_rch = lct.getChild(1, num_to);

    // emit Delegate(msg.sender, _to, block.number);
    emit ShowNode(msg.sender, num_sender, sender_fa);

    emit ShowNode(_to, num_to, fa_to);
    emit ReDelegate(num_sender,num_old, num_to);
  }

  function undelegate() public {
    address old = v_to_parent[msg.sender];
    require(old!=address(0x0), "have no delegatee to undelegate");
    
    lct.cut(msg.sender, old);
    address[] storage children = v_to_children[old];
    children.remove(msg.sender);
    v_to_parent[msg.sender] = address(0x0);
    
    uint32 num_sender = lct.getAddrNum(msg.sender);
    emit Undelegate(num_sender, lct.getAddrNum(old));
    emit ShowNode(msg.sender, num_sender, 0);
    
  }

  function getDelegator(address addr, uint height) public view returns(address ){
    //require(v_to_parent[addr] != address(0x0), "no parent");
    return v_to_parent[addr];
  }

  function getDelegatee(address addr, uint height) public view returns (address [] memory){
    return v_to_children[addr];
  }

  function getWeight(address addr, uint height) public view returns(uint) {
    return vote_weight[addr];
  }
  function getVoterCount(uint height) public view returns(uint){
    return voter_count;
  }
}
