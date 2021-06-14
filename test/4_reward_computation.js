'use strict';
const truffleCost = require('truffle-cost');
const truffleAssert = require('truffle-assertions');
const time = require('./helper/timeshift');
const BN = require('bn.js');
require('chai').use(require('chai-bn')(BN)).should();

const Token = artifacts.require("iBNB");
const routerContract = artifacts.require('IUniswapV2Router02');
const pairContract = artifacts.require('IUniswapV2Pair');
const routerAddress = "0x10ED43C718714eb63d5aA57B78B54704E256024E";


contract("Reward computation", accounts => {

  const to_send = 10**7;
  const amount_BNB = 98 * 10**18;
  const pool_balance = '98' + '0'.repeat(19);
  //98 BNB and 98*10**10 iBNB -> 10**10 iBNB/BNB
  const tot_sup = '1' + '0'.repeat(24);
  const half_sup = '5' + '0'.repeat(23);

  before(async function() {
    const x = await Token.new(routerAddress);
  });

  describe("Setting the Scene", () => {

    it("Adding Liq", async () => { //from 2_liqAdd & Taxes
      const x = await Token.deployed();
      await x.setCircuitBreaker(true, {from: accounts[0]});
      const router = await routerContract.at(routerAddress);
      const sender = accounts[0];

      let _ = await x.approve(routerAddress, pool_balance);
      await router.addLiquidityETH(x.address, pool_balance, 0, 0, accounts[0], 1907352278, {value: amount_BNB}); //9y from now. Are you from the future? Did we make it?

      const pairAdr = await x.pair.call();
      const pair = await pairContract.at(pairAdr);
      const LPBalance = await pair.balanceOf.call(accounts[0]);

      await x.setCircuitBreaker(false, {from: accounts[0]});

      assert.notEqual(LPBalance, 0, "No LP token received / check Uni pool");
    });

    it("Sending 1 BNB and 50% supply to EOA", async () => { //from 2_liqAdd & Taxes
      const x = await Token.deployed();
      await x.setCircuitBreaker(true, {from: accounts[0]});
      await x.transfer(accounts[1], half_sup, {from: accounts[0]});
      await x.setCircuitBreaker(false, {from: accounts[0]});
      await x.send('1'+'0'.repeat(18), {from: accounts[5]});
      const bal = await web3.eth.getBalance(x.address);
      assert.equal(bal, '1'+'0'.repeat(18), "No BNB received");
      const bal_token = await x.balanceOf(accounts[1]);
      assert.equal(bal_token, half_sup, "No token received");
    });
  });

  describe("computeReward()", () => {

    // 98 * 10**19 in pool
    // owned: 5*10**23
    //
    let init_reward;
    let reinit_reward;

    it("Reward at t=0 - theo:0", async () => {
      const x = await Token.deployed();
      const reward_and_tax = await x.computeReward({from: accounts[1]});
      const reward = reward_and_tax[0];
      console.log("t0 : "+reward.toString());
      assert.equal(reward, 0, "Invalid reward");
    });

    it("Reward at t=1 sec", async () => {
      const x = await Token.deployed();
      await time.advanceTimeAndBlock(1);
      const reward_and_tax = await x.computeReward({from: accounts[1]});
      const reward = reward_and_tax[0];
      init_reward = reward;
      console.log("t1 : "+reward.toString());
      assert.notEqual(reward, 0, "Invalid reward");
    });

    it("Reward at t=6h", async () => {
      const x = await Token.deployed();
      await time.advanceTimeAndBlock(21600);
      const reward_and_tax = await x.computeReward({from: accounts[1]});
      const reward = reward_and_tax[0];
      console.log("t6h : "+reward.toString());
      assert.notEqual(reward, 0, "Invalid reward");
    });

    it("Reward at t=24h", async () => {
      const x = await Token.deployed();
      await time.advanceTimeAndBlock(86400-2-21600);
      const reward_and_tax = await x.computeReward({from: accounts[1]});
      const reward = reward_and_tax[0];
      console.log("t24h : "+reward.toString());
      assert.equal(reward, 0, "Invalid reward");
    });

    it("Reward at t=24h01", async () => {
      const x = await Token.deployed();
      await time.advanceTimeAndBlock(1);
      const reward_and_tax = await x.computeReward({from: accounts[1]});
      reinit_reward = reward_and_tax[0];
      console.log("t1 : "+init_reward.toString());
      console.log("t24h00:01 : "+reinit_reward.toString());
      assert.equal(init_reward.toNumber(), reinit_reward.toNumber(), "Invalid periodicity");
    });


  });




});
