// SPDX-License-Identifier: GPL

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";





/**
 * @dev iBNB
 *
 *
 *
 *
 */

contract iBNB is IERC20, Ownable {
    using SafeMath for uint256;

    struct past_tx {
      uint256 last_timestamp;
      uint256 cum_transfer; //this is not what you think, you perv
    }

    mapping (address => uint256) private _balances;
    mapping (address => past_tx) private _last_tx;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public excluded_from_taxes;

    uint256 private _decimals = 9;
    uint256 private _totalSupply = 10**15 * 10**_decimals;
    uint256 genesis_timestamp;

    //@dev in percents : 0.125% - 0.25 - 0.5 - 0.75 - 0.1%
    //therefore value are div by 10**7
    uint16[5] public selling_taxes_tranches = [125, 250, 500, 750, 1000];
    uint8[4] public selling_taxes_rates = [2, 4, 6, 8];


    string private _name = "iBNB";
    string private _symbol = "iBNB";

    IUniswapV2Pair pair;
    IUniswapV2Router02 router;

    event TaxRatesChanged();

    constructor (address _router) {
         _balances[msg.sender] = _totalSupply;
         //create pair to get the pair address
         router = IUniswapV2Router02(_router);
         IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
         pair = IUniswapV2Pair(factory.createPair(address(this), router.WETH()));

         genesis_timestamp = block.timestamp;
    }

    function decimals() public view returns (uint256) {
         return _decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }


//TODO: circuit breaker
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        uint256 sell_tax = 0;

        (uint112 _reserve0, uint112 _reserve1,) = pair.getReserves(); // returns reserve0, reserve1, timestamp last tx
        if(address(this) != pair.token0()) { // 0 := iBNB
          (_reserve0, _reserve1) = (_reserve1, _reserve0);
        }

        if(sender != address(pair) && excluded_from_taxes[sender] == false) {
          sell_tax = sellingTax(sender, amount, _reserve0);
        }
        // else sell_tax stays 0;


        //9.9 and 1%

        //balancer call



        //@dev every extra token are collected into address(this), it's the balancer job to then split them
        //between pool and reward
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount - sell_tax ;
        _balances[address(this)] += sell_tax;

        emit Transfer(sender, recipient, amount);
        emit Transfer(sender, address(this), sell_tax);
    }

//TODO Gas optim
    //@dev take a selling tax if transfer from a non-excluded address or from the pair contract exceed
    //the thresholds defined in selling_taxes_thresholds on a daily (calendar) basis
  function sellingTax(address sender, uint256 amount, uint256 pool_balance) private returns(uint256) {

        uint16[5] memory _tax_tranches = selling_taxes_tranches; //gas optim
        past_tx memory sender_last_tx = _last_tx[sender];
        uint256 sell_tax = 0;

        //num days since genesis > num of days since last tx ?
        if((block.timestamp - genesis_timestamp) / 8400 > (block.timestamp - sender_last_tx.last_timestamp) / 8400) {
          _last_tx[sender].cum_transfer = 0;
        }

        uint256 new_cum_sum = amount.add(_last_tx[sender].cum_transfer);

        if(new_cum_sum > pool_balance.mul(_tax_tranches[4]).div(10**7)) {
          revert("Selling tax: above max amount");
        }
        else if(new_cum_sum > pool_balance.mul(_tax_tranches[3]).div(10**7)) {
          sell_tax = amount.mul(selling_taxes_rates[3]).div(100);
        }
        else if(new_cum_sum > pool_balance.mul(_tax_tranches[2]).div(10**7)) {
          sell_tax = amount.mul(selling_taxes_rates[2]).div(100);
        }
        else if(new_cum_sum > pool_balance.mul(_tax_tranches[1]).div(10**7)) {
          sell_tax = amount.mul(selling_taxes_rates[1]).div(100);
        }
        else if(new_cum_sum > pool_balance.mul(_tax_tranches[0]).div(10**7)) {
          sell_tax = amount.mul(selling_taxes_rates[0]).div(100);
        }
        //else sell_tax stays at 0

        _last_tx[sender].last_timestamp = block.timestamp;
        _last_tx[sender].cum_transfer = sender_last_tx.cum_transfer.add(amount);

        return sell_tax;
    }


    function setSellingTaxesTranches(uint16[5] memory new_tranches) public onlyOwner {
      selling_taxes_tranches = new_tranches;
      emit TaxRatesChanged();
    }

    function setSellingTaxesrates(uint8[4] memory new_amounts) public onlyOwner {
      selling_taxes_rates = new_amounts;
      emit TaxRatesChanged();
    }

//---------------------- TODO --------------------------------

    function balancer() private {

    }

    //@dev whe triggered, will get a quote and provide liquidity with a 20% max slippage
    function swapForLiquidity(uint256 amount) internal {

      (uint112 _reserve0, uint112 _reserve1,) = pair.getReserves(); // returns reserve0, reserve1, timestamp last tx
      if(address(this) != pair.token0()) { // 0 := iBNB
        (_reserve0, _reserve1) = (_reserve1, _reserve0);
      }
      //amount BNB = quote(amount token, reserve token, reserve bnb)
      uint256 current_quote_in_BNB = router.quote(amount, _reserve0, _reserve1);


    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}
