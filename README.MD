# deprecated -> see "iBNB" repo for updates + nodejs controllers

### iBNB


Every tx is subject to:
- a sell tax, at fixed tranches (see selling_taxes_tranches and selling_taxes_rates - above the last threshold, th tx revert).
  the sell tax is applicable on tx to the uni/pancake pool. This tax goes to the reward pool.
- 0.1% flat to the team wallet
- 9.9% to the balancer (which, in turn, fill 2 internal "pools" via the pro_balances struct: reward and liquidity).
- a "check and trigger" on both liquidity and reward internal pools -> if they have more token than the threshold, swap is triggered
   and BNB are stored in the contract (for the reward subpool) or liquidity is added to the uni pool

Reward is claimable daily, and is based on the % of the circulating supply (defined as total_supply-dead address balance-pool balance)
owned by the claimer; on the time since the last transfer into owner's wallet module 24; on the BNB balance of the contract :

reward in BNB = (token owned / circulating supply) * [(current time - last transfer in) % 24] / 1 day * BNB contract balance


Test on bsc mainnet:

## You'll have to change some contract' function visibility in order to pass all the tests (reduced for gas saving in prod version)

Launch ganache-cli -f https://bsc-dataseed.binance.org/ --account $PRIVATE_KEY,100000000000000000000000000000

or Launch ganache-cli -f https://bsc-dataseed.binance.org/ -m $MNEMO -a 20

And truffle test --network ganache --show-events

Or on testnet (migrations script will follow;)
