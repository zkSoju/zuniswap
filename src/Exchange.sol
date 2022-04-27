pragma solidity 0.8.13;

import {ERC20} from "@solmate/tokens/ERC20.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);

    function transfer(address to, uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}

contract Exchange is ERC20 {
    address public tokenAddress;

    constructor(address _token) ERC20("Zuniswap-V1", "ZUNI-V1", 18) {
        require(_token != address(0), "invalid token address");

        tokenAddress = _token;
    }

    function addLiquidity(uint256 _tokenAmount)
        public
        payable
        returns (uint256)
    {
        if (getReserve() == 0) {
            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), _tokenAmount);

            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);

            return liquidity;
        } else {
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserve();
            // required token deposit given ETH deposit and ratio of reserves
            uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve;
            require(_tokenAmount >= tokenAmount, "invalid token amount");

            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), tokenAmount);

            uint256 liquidity = (totalSupply * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);

            return liquidity;
        }
    }

    function removeLiquidity(uint256 _amount)
        public
        returns (uint256, uint256)
    {
        require(_amount > 0, "invalid amount");

        // withdraws are balanced in respect to ratio the LP tokens minted to current reserves
        uint256 ethAmount = (address(this).balance * _amount) / totalSupply;
        uint256 tokenAmount = (getReserve() * _amount) / totalSupply;

        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);

        return (ethAmount, tokenAmount);
    }

    function getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");

        // takes a 1% cut in fees
        // uniswap takes 0.3% but using 1% here for readability z
        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
        return numerator / denominator;
    }

    /// @dev Gets amount of tokens to return in exchange for ETH input
    function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
        require(_ethSold > 0, "ethSold is too small");

        uint256 tokenReserve = getReserve();

        return getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    /// @dev Gets amount of ETH to return in exchange for token input
    function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
        require(_tokenSold > 0, "tokenSold is too small");

        uint256 tokenReserve = getReserve();

        return getAmount(_tokenSold, tokenReserve, address(this).balance);
    }

    // @dev Gets token balance of current pool contract
    function getReserve() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    // @notice minTokens is defined in UI as slippage tolerance where user agrees to receive
    // at least minTokens amount

    // protects users from front-running bots that try to intercept tx and modify pool balances for profit
    function ethToTokenSwap(uint256 _minTokens) public payable {
        uint256 tokenReserve = getReserve();

        // we need to subtract msg.value because at this point in the function, the balance is
        // already added to the contract's balance

        // if we don't subtract the reserves will be heavily skewed prior to calculating prices
        // resulting in incorrect prices
        uint256 tokensBought = getAmount(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );

        require(tokensBought >= _minTokens, "insufficient output amount");

        IERC20(tokenAddress).transfer(msg.sender, tokensBought);
    }

    function tokenToEthSwap(uint256 _tokensSold, uint256 _minEth) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );

        require(ethBought >= _minEth, "insufficient output amount");

        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokensSold
        );
        payable(msg.sender).transfer(ethBought);
    }
}
