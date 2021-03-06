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
  event ShowNode(address addr, uint32 num, uint32 fa, uint32 lc, uint32 rc);
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
    uint32 num = lct.add_address(addr);
    // emit SetWeight(addr, weight, block.number);
  }

  function check_circle(address _from, address _to) internal view returns(bool){
    return false;
  }

  function delegate(address _to) public {
    require(_to != msg.sender, "cannot be self");
    require(vote_weight[msg.sender] != 0, "no sender");
    require(vote_weight[_to] != 0, "no _to");

    // 避免环路代理
    bool has_circle = lct.is_connected(msg.sender, _to);
    require(!has_circle, "can not be circle");

    // 避免重复代理
    address old = v_to_parent[msg.sender];
    require(old != _to, "repeat delegate");

    uint32 num_old = 0;
    if(old != address(0x0)){
      lct.undelegate(msg.sender, old);
      address[] storage children = v_to_children[old];
      children.remove(msg.sender);
      num_old = lct.add_address(old);
    }

    lct.delegate(msg.sender, _to);
    v_to_parent[msg.sender] = _to;
    v_to_children[_to].push(msg.sender);
    uint32 num_sender = lct.add_address(msg.sender);
    uint32 num_to = lct.add_address(_to);
    uint256 len = lct.getVchildLen();
    uint32 sender_lch = lct.getChild(0, num_sender);
    uint32 sender_rch = lct.getChild(1, num_sender);
    uint32 sender_fa = lct.add_address(_to);
    uint32 to_fa = lct.add_address(v_to_parent[_to]);
    uint32 to_lch = lct.getChild(0, num_to);
    uint32 to_rch = lct.getChild(1, num_to);

    emit Delegate(msg.sender, _to, block.number);
    emit ShowNode(_to, num_to, to_fa, to_lch, to_rch);
    emit ShowNode(msg.sender, num_sender, sender_fa, sender_lch, sender_rch);
    emit ReDelegate(num_sender,num_old, num_to);
  }

  function undelegate() public {
    address old = v_to_parent[msg.sender];
    require(old!=address(0x0), "have no delegatee to undelegate");
    lct.undelegate(msg.sender, old);
    uint32 from = lct.add_address(msg.sender);
    uint32 to = lct.add_address(old);
    emit Undelegate(from, to);
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
