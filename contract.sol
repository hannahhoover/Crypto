// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint256);
    function balanceOf(address tokenOwner) public virtual view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public virtual returns (bool success);
    function approve(address spender, uint256 tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract Coin is ERC20Interface, SafeMath {
    string public name = "MyCoin";
    string public symbol = "SIM";
    uint8 public decimals = 18;
    uint256 public _totalSupply = 2000000000000000000000000000; // 2 billion SIM in supply

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function _transfer(address from, address to, uint256 tokens) private returns (bool success) {
        uint256 amountToBurn = safeDiv(tokens, 20); // 5% of the transaction shall be burned
        uint256 amountToSendToCharity = safeDiv(tokens, 20); // 5% of the transaction shall be sent to charity
        uint256 amountToTransfer = safeSub(safeSub(tokens, amountToBurn), amountToSendToCharity);
                
        balances[from] = safeSub(balances[from], tokens);
        balances[address(0)] = safeAdd(balances[address(0)], amountToBurn);
        balances[address(0xc172542e7F4F625Bb0301f0BafC423092d9cAc71)] = safeAdd(balances[address(0xc172542e7F4F625Bb0301f0BafC423092d9cAc71)], amountToSendToCharity);
        balances[to] = safeAdd(balances[to], amountToTransfer);
        return true;
    }

    function approve(address spender, uint256 tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success) {
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        _transfer(from, to, tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
// Generate a random hash by using the next block's difficulty and timestamp
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }
    
    // Either win or lose some tokens according to the random number generator
    function bet(uint256 tokens) public returns (string memory) {
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        emit Transfer(msg.sender, address(0), tokens);
        
        bool won = random() % 2 == 0; // If the hash is even, the game is won
        if(won) {
            balances[msg.sender] = safeAdd(balances[msg.sender], safeMul(tokens, 2));
            emit Transfer(address(0), msg.sender, safeMul(tokens, 2));
            return 'You won!';
        } else {
            return 'You lost.';
        }
    }
}
