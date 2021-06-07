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
      uint256 cum_transfer; //this is not what you think, you perv
      uint256 BNB_basis_for_reward;
      uint256 last_timestamp; //no choice, uint256
    }

    struct prop_balances {
      uint256 reward_pool;
      uint256 liquidity_pool;
    }

    mapping (address => uint256) private _balances;
    mapping (address => past_tx) private _last_tx;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public excluded_from_taxes;

    uint256 private _decimals = 9;
    uint256 private _totalSupply = 10**15 * 10**_decimals;
    uint256 genesis_timestamp;
    uint256 public swap_for_liquidity_threshold = 10**14 * 10**_decimals; //10%
    uint256 public swap_for_reward_threshold = 10**14 * 10**_decimals;

//TODO gas optim:
    //@dev in percents : 0.125% - 0.25 - 0.5 - 0.75 - 0.1%
    //therefore value are div by 10**7
    uint16[5] public selling_taxes_tranches = [125, 250, 500, 750, 1000];
    uint8[4] public selling_taxes_rates = [2, 4, 6, 8];

    string private _name = "iBNB";
    string private _symbol = "iBNB";

    address LP_contract;
    address devWallet;

    IUniswapV2Pair pair;
    IUniswapV2Router02 router;

    prop_balances balancer_balances;

    event TaxRatesChanged();
    event swapForLiquidity(string);

    constructor (address _router) {
         _balances[msg.sender] = _totalSupply;
         //create pair to get the pair address
         router = IUniswapV2Router02(_router);
         IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
         pair = IUniswapV2Pair(factory.createPair(address(this), router.WETH()));

         genesis_timestamp = block.timestamp;
         LP_contract = msg.sender;  //temp set, then switch to the LP Lock
         devWallet = msg.sender;
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


//TODO: circuit breaker !!!!!
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 sell_tax = 0;
        uint256 balancer_amount;
        uint256 dev_tax;

        // ----  Sell tax  ----
        (uint112 _reserve0, uint112 _reserve1,) = pair.getReserves(); // returns reserve0, reserve1, timestamp last tx
        if(address(this) != pair.token0()) { // 0 := iBNB
          (_reserve0, _reserve1) = (_reserve1, _reserve0);
        }
        if(sender != address(pair) && excluded_from_taxes[sender] == false) {
          sell_tax = sellingTax(sender, amount, _reserve0); //will update the balancer ledger too
        }
        // else sell_tax stays 0;

        // ------ dev tax 0.1% -------
        dev_tax = amount.mul(1).div(1000);

        // ------ balancer tax 9.9% ------
        balancer_amount = amount.mul(99).div(1000);
        balancer(balancer_amount, _reserve0);


        //@dev every extra token are collected into address(this), it's the balancer job to then split them
        //between pool and reward, using his the dedicated struct
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount - sell_tax - dev_tax - balancer_amount;
        _balances[address(this)] += sell_tax + balancer_amount;
        _balances[devWallet] += dev_tax;

        emit Transfer(sender, recipient, amount);
        emit Transfer(sender, address(this), sell_tax);
        emit Transfer(sender, address(this), balancer_amount);
        emit Transfer(sender, devWallet, dev_tax);
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
          _last_tx[sender].BNB_basis_for_reward = amount;
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

        balancer_balances.reward_pool += sell_tax;

        return sell_tax;
    }

//---------------------- TODO balancer--------------------------------

//TODO : GAS OPTIM/Glob var
    //@dev take the 9.9% taxes as input, split it according to pool condition
    function balancer(uint256 amount, uint256 pool_balance) private {

      address DEAD = address(0x000000000000000000000000000000000000dEaD);
      uint256 ratio = pool_balance.mul(100).div(totalSupply()-_balances[DEAD]);

      balancer_balances.reward_pool += amount.mul(ratio).div(100);
      balancer_balances.liquidity_pool += amount.mul(100 - ratio).div(100);


      if(balancer_balances.liquidity_pool >= swap_for_liquidity_threshold) {
          uint256 token_out = addLiquidity(balancer_balances.liquidity_pool);
          balancer_balances.liquidity_pool -= token_out; //not balanceOf, in case addLiq revert
      }

      if(balancer_balances.reward_pool >= swap_for_reward_threshold) {
          uint256 token_out = addBNB(balancer_balances.reward_pool);
          balancer_balances.reward_pool -= token_out;
      }


    }

    //@dev when triggered, will get a quote and provide liquidity with a 20% max slippage
    //    BNBfromSwap being the difference between and after the swap, potential slippage
    //    will result in extra-BNB for the reward pool (free money for the guys:)
    function addLiquidity(uint256 token_amount) internal returns (uint256) {
      uint256 BNBfromReward = address(this).balance;

      address[] memory route = new address[](2);
      route[0] = address(this);
      route[1] = router.WETH();

      if(allowance(address(this), address(router)) < token_amount) {
        _approve(address(this), address(router), ~uint256(0));
      }

      try router.swapExactTokensForETHSupportingFeeOnTransferTokens(token_amount.div(2), 0, route, address(this), block.timestamp) {
        uint256 BNBfromSwap = address(this).balance.sub(BNBfromReward);
        router.addLiquidityETH{value: BNBfromSwap}(address(this), token_amount.div(2), 0, 0, LP_contract, block.timestamp); //will not be catched
      }
      catch {
        emit swapForLiquidity("swapToken failure");
        return 0;
      }

      emit swapForLiquidity("Liquidity added");
      return token_amount;
    }

    function addBNB(uint256 token_amount) internal returns (uint256) {
      address[] memory route = new address[](2);
      route[0] = address(this);
      route[1] = router.WETH();

      if(allowance(address(this), address(router)) < token_amount) {
        _approve(address(this), address(router), ~uint256(0));
      }

      try router.swapExactTokensForETHSupportingFeeOnTransferTokens(token_amount, 0, route, address(this), block.timestamp) {
        emit swapForLiquidity("Liquidity added");
        return token_amount;
      }
      catch {
        emit swapForLiquidity("swapToken failure");
        return 0;
      }


    }

    function resetBalancer() public onlyOwner {
      uint256 _contract_balance = balanceOf(address(this));
      balancer_balances.reward_pool = _contract_balance.div(2);
      balancer_balances.liquidity_pool = _contract_balance.div(2);
    }

//-----------------------------TODO BNB reward computing&claim + tax


    function setLPContract(address _LP_contract) public onlyOwner {
      LP_contract = _LP_contract;
    }
    function setDevWallet(address _devWallet) public onlyOwner {
      devWallet = _devWallet;
    }
    function setSwapThreshold(uint256 threshold_in_token) public onlyOwner {
      swap_for_liquidity_threshold = threshold_in_token * 10**_decimals;
    }

    function setSellingTaxesTranches(uint16[5] memory new_tranches) public onlyOwner {
      selling_taxes_tranches = new_tranches;
      emit TaxRatesChanged();
    }

    function setSellingTaxesrates(uint8[4] memory new_amounts) public onlyOwner {
      selling_taxes_rates = new_amounts;
      emit TaxRatesChanged();
    }
}
