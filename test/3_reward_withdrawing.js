const Token = artifacts.require("iBNB");
const truffleCost = require('truffle-cost');
const truffleAssert = require('truffle-assertions');
const routerContract = artifacts.require('IUniswapV2Router02');
const pairContract = artifacts.require('IUniswapV2Pair');
const routerAddress = "0x10ED43C718714eb63d5aA57B78B54704E256024E";


contract("Token", accounts => {

  const to_send = 10**7;
  const amount_BNB = 50 * 10**18;
  const pool_balance = '1' + '0'.repeat(20);

  before(async function() {
    const x = await Token.new(routerAddress);
  });

  describe("Setting the Scene", () => {

    it("Adding Liq", async () => { //from 2_liqAdd & Taxes
      const x = await Token.deployed();
      await x.setCircuitBreaker(true, {from: accounts[0]});
      const status_circ_break = await x.circuit_breaker.call();
      const router = await routerContract.at(routerAddress);
      const amount_token = pool_balance;
      const sender = accounts[0];

      let _ = await x.approve(routerAddress, amount_token);
      await router.addLiquidityETH(x.address, amount_token, 0, 0, accounts[0], 1907352278, {value: amount_BNB}); //9y from now. Are you from the future? Did we make it?

      const pairAdr = await x.pair.call();
      const pair = await pairContract.at(pairAdr);
      const LPBalance = await pair.balanceOf.call(accounts[0]);

      await x.setCircuitBreaker(false, {from: accounts[0]});

      assert.notEqual(LPBalance, 0, "No LP token received / check Uni pool");
    });

    it("Lowering SwapForLiqThreshold", async () => {
      const x = await Token.deployed();
      await x.setSwapFor_Reward_Threshold(1);
      const val = await x.swap_for_reward_threshold.call();
      assert.equal(val.toNumber(), 1*10**9, "Wrong threshold");
    });


  });

  describe("Regular transfers", () => {

    it("Transfer standards: 10x10", async () => {
      const x = await Token.deployed();

      for (let i = 1; i < 10; i++) {
        await x.transfer(accounts[i], to_send*100, { from: accounts[0] });
      }

      for (let i = 1; i < 10; i++) {
        for (let j = 1; j < 10; j++) {
          await truffleCost.log(x.transfer(accounts[j], to_send*10, { from: accounts[i] }), 'USD'); //will return LAST cost only
        }
      }

      const newBal = await x.balanceOf.call(accounts[1]);
      assert.notEqual(newBal.toNumber(), 0, "Transfer Failure");
    });

    it("Reward pool status", async () => {
      const x = await Token.deployed();
      const a = await x.balancer_balances.call();
      const reward_obs_pool = a[0].toNumber();
      console.log(reward_obs_pool);
      assert.notEqual(reward_obs_pool, 0, "Reward pool failure");
    });


  describe("Reward Mechanic", () => {
    it("BNB balance", async () => {
      const x = await Token.deployed();

      const bal = await web3.eth.getBalance(x.address);
      console.log(bal);
      assert.notEqual(bal, 0, "Swap Failure");
    });
  });
/*

    //@dev /!\ reward pool receive the sell tax as well !!!
    it("Transfer standard: balancer balances", async () => {
      const x = await Token.deployed();
      const bal = await x.balancer_balances.call();
      const bal_sum = bal[0].toNumber() + bal[1].toNumber()
      assert.equal(bal_sum, to_send * 99/1000 + (to_send * 2 / 100) , "Incorrect amount transfered to balancer pools");
    });


    it("Transfer standard: Reward pool status", async () => {
      const x = await Token.deployed();
      const totalSupply = await x.totalSupply.call();

      const t = to_send * 99 / 1000 * (pool_balance / totalSupply);//9.9% of 1260000 * (pool_balance / circ_supply) +
      const reward_theo_pool = t + (to_send * 2 / 100);
      const a = await x.balancer_balances.call();
      const reward_obs_pool = a[0];

      assert.equal(reward_obs_pool.toNumber(), reward_theo_pool, "incorrect reward pool");
    });

    it("Transfer standard: Liquidity pool status", async () => {
      const x = await Token.deployed();
      const totalSupply = await x.totalSupply.call();

      const liq_theo_pool = to_send * 99 / 1000 * (1 -(pool_balance / totalSupply)); //9.9% of 1260000 * [1 - (pool_balance / circ_supply)]
      const a = await x.balancer_balances.call();
      const liq_obs_pool = a[1];

      assert.equal(liq_obs_pool.toNumber(), liq_theo_pool, "incorrect reward pool");
    });

  });*/
  });
});
