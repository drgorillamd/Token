pragma solidity >=0.6.8 <0.8.0;
// SPDX-License-Identifier: GPL - @DrGorilla_md (Tg/Twtr)

/* MyDawgy Presale contract
* No liabilities/DYOR/read the code/etc
* This is part of a bigger presale contract incl whitelisting (not needed here)
*
* After 10% of the total supply has been sold, no more buy is allowed (will revert)
* Owner then call concludeAndAddLiquidity to transfer the liq to the pool and
* call selfdestruct, effectively "deactivating" this contract.
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "pancakeswap-peripheral/contracts/interfaces/IPancakeRouter02.sol";

contract iBNB-presale is Ownable {

using SafeMath for uint256;

// -- variables --

    mapping (address => uint256) whitelist;

    enum status {
      beforeSale,
      whitelistSale,
      randomSale,
      postSale
    }

    status public sale_status;

    uint256 public nbOfTokenPerBNB = 500_000_000_000;  //pre-sale price (500b token/BNB)
    uint256 private init_balance;

    uint256 decimal;
    ERC20 public iBNB_token;
    IPancakeRouter02 router;

    event Buy(address, uint256, uint256);
    event LiquidityTransferred(uint256, uint256);

    modifier beforeSale() {
      require(sale_status == status.beforeSale, "Sale: already started");
      _;
    }

    modifier whitelistSale() {
      require(sale_status == status.whitelistSale, "Sale: not in whitelistSale");
      _;
    }

    modifier randomSale() {
      require(sale_status == status.randomSale, "Sale: not in randomSale");
      _;
    }

    modifier postSale() {
      require(sale_status == status.postSale, "Sale: not in postSale");
      _;
    }

// -- init --
    constructor(address _router, address _token_address) public {
        require(router.WETH() != address(0), 'wrong router');
        token = ERC20(_token_address);
        decimal = token.decimals();
        sale_status = status.presale;
    }

    function addWhitelisted

    function addRandomized



// -- sale --

    function startWhitelistSale() external beforeSale onlyOwner {
      sale_status = status.whitelistSale;
      init_balance = token.balanceOf(address(this));
    }


    //@dev contract starts with whole supply
    //     will revert when < 0 token available
    function tokenLeft() public view returns (uint256) {
      uint256 already_sold = init_balance.sub(token.balanceOf(address(this)));
      uint256 ten_percent = token.totalSupply().div(10);
      return (ten_percent.sub(already_sold, "Sale: No more token to sell")).div(10**decimal); //10%TS - already sold < 0 ?

    }

    function buy() external payable duringSale {
      require(msg.value <= 5 * 10**18, "Sale: Above max amount"); // 5 BNB
      require(msg.value >= 2 * 10**17, "Sale: Under min amount"); // 0.2 BNB

      uint256 amountToken = msg.value.mul(nbOfTokenPerBNB).div(10**18);
      require(amountToken <= tokenLeft(), "Sale: Not enough token left");

      token.transfer(msg.sender, amountToken.mul(10**decimal));
      emit Buy(msg.sender, msg.value, amountToken.mul(10**decimal));
    }

// -- post sale --

    //@dev convert BNB received and token left in pool liquidity. LP send to owner.
    //     Uni Router handles both scenario : existing and non-existing pair
    //     /!\ will revert if < 1BNB in contract
    //@param TokenPerBNB inital number of token for 1 BNB in the pool
    //@param min_amount_slippage_in_percents min amount for adding liquidity (see uniswap doc)
    //       in case of preexisting pool, if volatiltity++, set to 1% -> max slippage
    function concludeAndAddLiquidity(uint256 TokenPerBNB, uint256 min_amount_slippage_in_percents) external onlyOwner {

      sale_status = status.postSale;

      uint256 balance_BNB = address(this).balance.div(10**18);
      uint256 balance_token = token.balanceOf(address(this)).div(10**decimal);

      if(balance_token.div(balance_BNB) >= TokenPerBNB) { // too much token for BNB
         balance_token = TokenPerBNB.mul(balance_BNB);
       }
       else { // too much BNB for token left
         balance_BNB = balance_token.div(TokenPerBNB);
       }

      token.approve(address(router), balance_token.mul(10**decimal));
      router.addLiquidityETH{value: balance_BNB.mul(10**18)}(
          address(token),
          balance_token.mul(10**decimal),
          balance_token.mul(10**decimal).mul(min_amount_slippage_in_percents).div(100),  //slippage is evitable...
          balance_BNB.mul(10**18).mul(min_amount_slippage_in_percents).div(100),
          owner(),
          block.timestamp
      );

      //burn the non-used tokens
      if(token.balanceOf(address(this)) != 0) {
        token.transfer(0x000000000000000000000000000000000000dEaD, token.balanceOf(address(this)));
      }

      emit LiquidityTransferred(balance_BNB, balance_token);
      //retrieving BNB left (hopefully 0) + gas optimisation
      selfdestruct(payable(msg.sender));
  }


}
