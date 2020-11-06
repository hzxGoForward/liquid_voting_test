pragma solidity >=0.4.21 <0.6.0;

contract LinkCutTree {
    mapping(address => uint32) public mAddr_number; // node’s address to number
     uint8[]  public vtag;
     uint32[] public vfather;
     // 数组的定义方式看起来是2行n列的形式，但是实际上是N行2列的矩阵，访问时vchild[a][b]表示第a行第b列，这里和c++不同
     uint32[2][] public vchild;
     uint32 public node_count;
    // uint[] weight;

    event AddAddress(address from, uint32 num);
    event Access(uint32 num);

    constructor() public {
        node_count = 0;
        vfather.push(0);
        vtag.push(0);
        vchild = new uint32[2][](0);
        vchild.push([uint32(0),0]);
    }


    // judge x is a left child or a right child in a splay.
    function getch(uint32 x) public view returns (uint32) {
        uint32 ans = 0;
        if (vchild[vfather[x]][1] == x) ans += 1;
        return ans;
    }

    // judge wheter x is the root of its splay.
    function isroot(uint32 x) public view returns(bool){
        bool ans = false;
        uint32 f = vfather[x];
        if(f == 0 || (vchild[f][0] != x && vchild[f][1] != x))
            ans = true;
        return ans;
    }

    // transmit information from x to its children.
    function pushdown(uint32 x)public {
        if(vtag[x] == 1){
            if (vchild[x][0] > 0){
                uint32 temp = vchild[vchild[x][0]][0];
                vchild[vchild[x][0]][0] = vchild[vchild[x][0]][1];
                vchild[vchild[x][0]][1] = temp;
                vtag[vchild[x][0]] ^= 1;
            }
            if (vchild[x][1] > 0){
                uint32 temp = vchild[vchild[x][1]][0];
                vchild[vchild[x][1]][0] = vchild[vchild[x][1]][1];
                vchild[vchild[x][1]][1] = temp;
                vtag[vchild[x][1]] ^= 1;
            }
            vtag[x] = 0;
        }
    }

    // update info from its corresponding splay root to x.
    function update(uint32 x) public {
        if(!isroot(x))
            update(vfather[x]);
        pushdown(x);
    }

    // rotate a node x
    function rotate(uint32 x)public{
        if(isroot(x)){
            return;
        }
        uint32 y = vfather[x];
        uint32 z = vfather[y];
        uint32 chx = getch(x);
        uint32 chy = getch(y);
        vfather[x] = z;
        if (!isroot(y))
            vchild[z][chy] = x;
        uint32 idx = chx ^ 1;
        vchild[y][chx] = vchild[x][idx];
        vfather[vchild[x][idx]] = y;
        vchild[x][idx] = y;
        vfather[y] = x;
    }

    // rotate x to be the root of its splay
    function splay(uint32 x) public{
        // update information in the path which is from the root to x.
        update(x);
        uint32 f;
        // while 保证x一定可以旋转到根节点位置
        while (!isroot(x))
        {
            f = vfather[x];
            if (!isroot(f)){
                uint32 chx = getch(x);
                uint32 chy = getch(f);
                if(chx == chy){
                    rotate(f);
                }
                else{
                    rotate(x);
                }
            }
            rotate(x);
        }
    }

    // create a path from the root to x.
    function access(uint32 x) public{
        // 将最后一个点的右儿子变为0，即变为虚边
        uint32 son = 0;
        while(x>0){
            // 将x转换为当前树的树根
            splay(x);
            // 将x的右儿子设置为前一棵splay树的树根
            // require(vchild[1].length >x, "HZX--ARRAY LENGTH ERROR--HZX");
            // 这一句出现了bug，为什么？
            vchild[x][1] = son;
            // // son 保存当前splay树树根，x是其父节点
            son = x;
            x = vfather[x];
            // x = 0;
        }
    }

    // 将原来的树中x节点作为根节点
    function makeroot(uint32 x) public
    {
        access(x);
        // splay(x) 之后x在这个树的最右下角 
        splay(x);
        // 交换x的左孩子节点和右孩子节点
        uint32 temp = vchild[x][0];
        vchild[x][0] = vchild[x][1];
        vchild[x][1] = temp;
        // 进行懒人标记，不再递归的进行翻转
        vtag[x] ^= 1;
    }

    // 寻找x节点在原树的根节点
    function findRoot(uint32 x) public returns (uint32)
    {
        access(x);
        splay(x);
        // 最左边的一定是根节点
        while (vchild[x][0]>0)
        {
            // 下传懒标记
            pushdown(x);
            x = vchild[x][0];
        }
        // 对根节点进行splay，保证时间复杂度
        splay(x);
        return x;
    }

    // 把x到y的路径拆成一棵方便的Splay树
    function split(uint32 x, uint32 y) public
    {
        // 如果x和y根本不在同一条路径上，则跳过
        if (findRoot(x) != findRoot(y))
            return;
        makeroot(x);
        access(y);
        splay(y);
    }

 // _from delegates its voting power to _to
    function delegate(address _from, address _to) public returns(bool){
        bool has_path = is_connected(_from, _to);
        require(!has_path, "cannot be circle");
        uint32 num_from = add_address(_from);
        uint32 num_to = add_address(_to);
        makeroot(num_from);
        vfather[num_from] = num_to;
        return true;
    }

    // _from delegates its voting power to _to
    function undelegate(address _from, address _to) public returns(bool){
        uint32 x = add_address(_from);
        uint32 y = add_address(_to);
        makeroot(y);
        // 如果y和x不在一棵树上，或者x和y之间不邻接(x的父亲不是y 或者x有左儿子)，不进行cut
        uint32 f = vfather[x];
        bool connected = (findRoot(x) != y )|| (f != y) || (vchild[x][0]>0);
        require(connected, "have no delegation relationship");
        vfather[x] = 0;
        vchild[y][1] = 0;
        update(y);
        return true;
    }

    // check wheter there is a path between _from and to
    function is_connected(address _from, address _to) public returns(bool){
        uint32 from_number = mAddr_number[_from];
        uint32 to_number = mAddr_number[_to];
        require(from_number<=node_count, "number is valid");
        require(to_number<=node_count, "number is valid");
        bool ans = false;
        if(from_number == 0|| to_number == 0){
            ans = true;
        }
        // else if(findRoot(from_number) == findRoot(to_number)){
        //     ans = true;
        // }
        return ans;
    }

        // add a new address
    function add_address(address addr) public returns(uint32){
        if (mAddr_number[addr] == 0) {
            ++node_count;
            mAddr_number[addr] = node_count;
            vfather.push(0);
            vtag.push(0);
            vchild.push([uint32(0),0]);
        }
        return mAddr_number[addr];
    }

    function getVchildLen() public view returns(uint256){
        return vchild.length;
    }

    function getNodeCnt() public view returns(uint32){
        return node_count;
    }

    function getFather(uint32 x) public view returns(uint32){
        return vfather[x];
    }

    function getChild(uint32 pos, uint32 x) public view returns(uint32){
        if(pos == 1){
            return vchild[x][pos];
        }
        else{
            return vchild[x][pos];
        }
    }

}
