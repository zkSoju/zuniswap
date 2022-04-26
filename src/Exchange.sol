pragma solidity 0.8.13;

interface IERC20 {
    function balanceOf(address) external returns (uint256);

    function transfer(address to, uint256 amount) external;
}


contract Exchange {
  address public tokenAddress;

  constructor(address _token){
    require(_token != address(0), "invalid token address");

    tokenAddress = _token;
  }

  function addLiquidity(uint256 _tokenAmount) public payable {
    IERC20 token = IERC20(tokenAddress);
    token.transferFrom(msg.sender, address(this), _tokenAmount);
  }

  function getReserve() public view returns (uint256) {
    return IERC20(tokenAddress).balanceOf(address(this));
  }
}