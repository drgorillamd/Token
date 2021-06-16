pragma solidity >=0.6.0 <0.8.0;
// SPDX-License-Identifier: GPL - @DrGorilla_md (Tg/Twtr)

/* SOHO Presale contract
*
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';


contract DawgyPresale is Ownable {

// -- var --
    using SafeMath for uint256;

    enum status {
      presale,
      sale,
      postSale
    }

    status sale_status;

    uint256 individualCapInBNB;
    uint256 nbOfTokenPerBNB;

    IERC20 token;
    address uniPair;
    IUniswapV2Router02 router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);//BSC Mainnet
    // address _WETH = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1).WETH(); //BSC Testnet

    mapping (address => uint256) private allowanceOf;

    event PriceAndCap(uint256, uint256);
    event AddToWhitelist(address);
    event RemoveFromWhitelist(address);
    event Buy(address, uint256);
    event LiquidityTransferred();

    modifier beforeSale() {
      require(sale_status == status.presale, "Sale: already started");
      _;
    }

    modifier duringSale() {
      require(sale_status == status.sale, "Sale: not active");
      _;
    }

    modifier postSale() {
      require(sale_status == status.postSale, "Sale: sale not over");
      _;
    }


// -- init --
    constructor(address _token_address) {
        token = IERC20(_token_address);
        sale_status = status.presale;
    }


// -- presale --
    function setPriceAndCap(uint256 _individualCapInBNB, uint256 _nbOfTokenPerBNB) external onlyOwner beforeSale {
      individualCapInBNB = _individualCapInBNB;
      nbOfTokenPerBNB = _nbOfTokenPerBNB;
      emit PriceAndCap(individualCapInBNB, nbOfTokenPerBNB);

    }

    //@dev whitelisting can be modified during the sale.
    //     If this is not expected behavior, add the duringSale modifier
    function addWhitelisting(address adr) external onlyOwner {
      require(allowanceOf[adr] == 0, "Whitelist: Address already whitelisted");
      allowanceOf[adr] = individualCapInBNB;
      emit AddToWhitelist(adr);
    }

    function removeWhitelisting(address adr) external onlyOwner {
      require(allowanceOf[adr] != 0, "Whitelist: address not whitelisted");
      allowanceOf[adr] = 0;
      emit RemoveFromWhitelist(adr);
    }

// -- sale --
    function startSale() external onlyOwner {
      sale_status = status.sale;
    }

    function getAllowanceLeftInBNB(address adr) external view returns(uint256) {
      return allowanceOf[adr];
    }

    //@dev max total buy is based only on whitelisted allowance cumsum - act accordingly
    function buy() external payable duringSale {
      require(allowanceOf[msg.sender] > 0, "Whitelist: 0 allowance");
      require(allowanceOf[msg.sender] >= msg.value, "Sale: Too much BNB sent");
      _buy(msg.sender, msg.value);
      emit Buy(msg.sender, msg.value);
    }


    function _buy(address sender, uint256 amountBNB) internal {
      allowanceOf[sender] = allowanceOf[sender].sub(amountBNB, "Internal: _buy: underflow");
      uint256 amountToken = amountBNB * nbOfTokenPerBNB;
      token.transfer(sender, amountToken);
    }

// -- post sale --

    //@dev convert BNB received and token left in pool liquidity. LP send to owner.
    //     Uni Router handles both scenario : existing and non-existing pair
    //@param TokenPerBNB inital number of token for 1 BNB in the pool
    //@param liquidityRatioInPercents ratio of presale BNB sent to the pool
    //       while the rest is transfered back to owner()
    function concludeAndAddLiquidity(uint256 TokenPerBNB, uint256 liquidityRatioInPercents) external onlyOwner {

      uint256 balance_BNB = address(this).balance;
      uint256 balance_token = token.balanceOf(address(this));

      uint256 BNB_for_pool = balance_BNB.mul(liquidityRatioInPercents).div(100);

      if(balance_token.div(BNB_for_pool) >= TokenPerBNB) {
         balance_token = TokenPerBNB * BNB_for_pool;
       } else {
         BNB_for_pool = balance_token.div(TokenPerBNB);
       }


      TransferHelper.safeApprove(address(token), address(router), balance_token);
      router.addLiquidityETH{value: BNB_for_pool}(
          address(this),
          balance_token,
          0, // sLiPpaGe iS uNaVoIdAbLe --> TODO : sanity check (someone already created the pair with wrong ratio?)
          0, // sLiPpaGe iS uNaVoIdAbLe --> TODO : id.
          owner(),
          block.timestamp
      );
      TransferHelper.safeTransferETH(msg.sender, address(this).balance); //transfer the rest

      emit LiquidityTransferred();


    }



// -- div --
//@dev prevent this contract being spammed by shitcoins
fallback () external {
    revert();
  }

}
