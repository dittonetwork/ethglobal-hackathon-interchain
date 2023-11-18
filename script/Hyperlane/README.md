# EthGlobal Hackathon: Hyperlane Automation Case Study

In our EthGlobal Hackathon entry, we present a cutting-edge application of Hyperlane's Messaging Protocol, combined with sophisticated Gelato automation and Celer bridging services. This project is designed to demonstrate seamless operational flow across diverse blockchain networks, harnessing the strength of Hyperlane's infrastructure. Our demonstration focuses on an innovative concept: "Fetch and Process". This involves retrieving assets from smart contract account vaults located on various networks and then employing automation services to effectively manage the incoming funds.

Transaction on Avalanche to request USDC token from Optimism and WETH from PolygonZkEVM and run automation on Avalanche upon receive.[]

<img width="1095" alt="image" src="https://github.com/dittonetwork/ethglobal-hackathon-interchain/assets/121140761/04a19fe6-3f5b-4850-91e9-615af16ace87">



1. **Initial State and Script Flow:**
    - The owner starts with a native currency on Network 1, 2, and 3, USDC on Network 2 and WETH on Network 3. The script's function is to deploy vaults across all three networks and deposit tokens on Networks 2 and 3. It packages bridge operations and a catch operation into a multicall, which is then called on the vault on Network 1.
2. **Cross-Chain Token Bridge Request:**
    - The **`sendTokenRequest`** function sends a cross-chain message to request tokens from two different networks: 2 and 3. We estimate fees and pay for execution with native currency of Network 1.
3. **Automation Creation:**
    - A stateful automation is created within the vault storage, complete with a unique key to run the automation.
4. **Register Automation Service:**
    - The created automation is registered with the Gelato Automation Service, enabling it to perform the necessary actions when conditions are met.
    - Compensation is paid out in native tokens to the executor for their services in the automation process.
    - The fee for executing the automation is deducted from the vault's balance in the end of the execution.
5. **Validation Post-Reception:**
    - After messags are received, a validation process ensures that the call originates from the correct message sender, confirming the legitimacy of the transaction.
6. **Token Bridge Back to Network 1:**
    - Tokens are sent back to the Network 1 from both Network 2 and 3, completing the tokenRequest.
7. **Celer Bridge Token Transfer:**
    - Celer Bridge resolves the message and facilitates the transfer of tokens to the vault on the Network 1.
8. **Execute Automation:**
    - The registered automation is executed, confirming the completion of predetermined conditions.
9. **Requested Token Receipt Check:**
    - The vault is checked to ensure that the balance of requested tokens is sufficient, indicating that both transfers from Network 2 and 3 have been completed successfully.
10. **Action and Event Emission:**
    - An event is emitted as an action, to signal the successful completion of the token transfers and the automation process.
11. **Cancel of the Automation:**
    - The automation is being automatically stopped (single execution). And fee paid to the executor.
---

## Running the Project

Follow these steps to set up and run the project. Ensure you have the necessary tools and tokens on various networks for successful deployment and execution.

### Prerequisites
- [Forge](https://github.com/foundry-rs/foundry) for smart contract development.
- A private key with sufficient native tokens across all networks for deployments.
- USDC tokens on Optimism on the deployed vault and WETH on PolygonZkEVM on the deployed vault. Use fresh private keys for consistent vault addresses. (After deployment you need to deposit the required token on the generated vault address on both Networks)

### Setup and Deployment

1. **Install Dependencies**:
   ```bash
   forge install
   ```

2. **Environment Configuration**:
   - Add your private key to the `.env` file. This is crucial for script execution and interaction with the blockchain.
   - Activate the virtual environment:
     ```
     source .env
     ```

3. **Deploying the Diamond Vault**:
   - For Avalanche Network:
     ```
     forge script script/Hyperlane/DeployerAvax.s.sol -vvvv --rpc-url $AVAX_RPC_URL --with-gas-price 25000000000 --broadcast
     ```
   - For Optimism Network:
     ```
     forge script script/Hyperlane/DeployerOp.sol -vvvv --rpc-url $OP_RPC_URL --broadcast
     ```
   - For PolygonZkEVM Network:
     ```
     forge script script/Hyperlane/DeployerZkEVM.sol -vvvv --rpc-url $ZKEVM_RPC_URL --broadcast
     ```

4. **Funding Vaults**:
   - Ensure each vault has enough tokens for operations.

5. **Executing the Main Script**:
   - To run the "fetch, collect, and execute" script:
     ```
     forge script script/Hyperlane/MainScript.s.sol -vvvv --rpc-url $AVAX_RPC_URL --with-gas-price 25000000000 --broadcast
     ```

### Monitoring Progress

- **Gelato Automation Explorer**:
  - Track the progress of the "balance checker" automation on the [Gelato Automation Explorer for Avalanche](https://app.gelato.network/).

- **Hyperlink Explorer**:
  - View cross-chain communication and transactions on the [Hyperlane Explorer](https://explorer.hyperlane.xyz/).