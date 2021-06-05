// SPDX-License-Identifier: GPL

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
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

contract iBNB is ERC20 {

    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _last_tx;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public excluded_from_taxes;

    uint256 private _decimals = 9;
    uint256 private _totalSupply = 10**15 * 10**_decimals;

    string private _name = "iBNB";
    string private _symbol = "iBNB";

    IUniswapV2Pair pool;
    IUniswapV2Router02 router;

    constructor (address _router) {
         _balances[msg.sender] = _totalSupply;
         //create pair to get the pair address
         router = IUniswapV2Router02(_router);
         IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
         pool = IUniswapV2Pair(factory.createPair(address(this), router.WETH()));

// TODO : retrieve token0 and 1 -> what is what (ordered by addresses in factory)
//ie which one is address(this) and save this for uni oracle
    }

    function decimals() public view virtual override returns (uint8) {
         return _decimals;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
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

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");

        uint256[3] memory current_reserves = pool.getReserves; // 0-> 1-> 2->
        uint256 current_quote = router.quote(A , reserveA, reserve B); //gas optim, only call once

        require(antiDump(sender, amount, quote), "iBNB: Max sell reached") //dumping_check -> to(pool) & > 0.1 in 24h


        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    //@dev prevent transaction >0.1bnb if not
    function anti_dump(address sender, uint256 amount) private returns(bool proceed) {
      if(sender != address(pool) && excluded_from_taxes[sender] == false) {
        // volume on 24h check
      }

    }



    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}
