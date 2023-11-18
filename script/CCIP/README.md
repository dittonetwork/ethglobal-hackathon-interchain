# EthGlobal Hackathon: Chainlink CCIP Automation Case Study

In our EthGlobal Hackathon entry, we present a cutting-edge application of Chainlink's Cross-Chain Interoperability Protocol (CCIP), combined with sophisticated automation services. This project is designed to demonstrate seamless operational flow across diverse blockchain networks, harnessing the strength of Chainlink's infrastructure. Our demonstration focuses on an innovative concept: "Fetch and Process". This involves retrieving assets from smart contract account vaults located on various networks and then employing automation services to effectively manage the incoming funds.

Transaction on Avalanche to request BNM token from Base and Optimism and run automation on Avalanche upon receive.[]

<img width="1110" alt="image" src="https://github.com/dittonetwork/ethglobal-hackathon-chainlink-ccip-automation/assets/121140761/75827ab7-e809-4e33-a3eb-85851ed89313">


1. **Initial State and Script Flow:**
    - The owner starts with a native currency on Network 1, 2, and 3. The script's function is to deploy vaults across all three networks and deposit BNM tokens on Networks 2 and 3. It packages bridge operations and a catch operation into a multicall, which is then called on the vault on Network 1.
2. **Cross-Chain Token Bridge Request:**
    - The **`sendTokenRequest`** function sends a cross-chain message to request tokens from two different networks: 2 and 3. We estimate fees and pay for execution with native currency of Network 1.
3. **Automation Creation:**
    - A stateful automation is created within the vault storage, complete with a unique key to run the automation.
4. **Register Automation Service:**
    - The created automation is registered with the Chainlink Automation Service, enabling it to perform the necessary actions when conditions are met.
    - Compensation is paid out in LINK tokens to the executor for their services in the automation process.
    - The fee for executing the automation is deducted from the vault's balance and put into the Upkeep.
5. **Validation Post-Reception:**
    - After messags are received, a validation process ensures that the call originates from the correct message sender, confirming the legitimacy of the transaction.
6. **Token Bridge Back to Network 1:**
    - Tokens are sent back to the Network 1 from both Network 2 and 3, completing the tokenRequest.
7. **Chainlink CCIP Token Transfer:**
    - Chainlink CCIP resolves the message and facilitates the transfer of tokens to the vault on the Network 1.
8. **Execute Automation:**
    - The registered automation is executed, confirming the completion of predetermined conditions.
9. **BNM Token Receipt Check:**
    - The vault is checked to ensure that the balance of BNM tokens is sufficient, indicating that both transfers from Network 2 and 3 have been completed successfully.
10. **Action and Event Emission:**
    - An event is emitted as an action, to signal the successful completion of the token transfers and the automation process.

---

## Running the Project

Follow these steps to set up and run the project. Ensure you have the necessary tools and tokens on various networks for successful deployment and execution.

### Prerequisites
- [Forge](https://github.com/foundry-rs/foundry) for smart contract development.
- A private key with sufficient native tokens across all networks for deployments.
- LINK tokens on all vaults across networks. Use fresh private keys for consistent vault addresses.

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
   - For Fuji Network:
     ```
     forge script script/CCIP/DeployerFuji.s.sol -vvvv --rpc-url $FUJI_RPC_URL --with-gas-price 25000000000 --broadcast
     ```
   - For Mumbai Network:
     ```
     forge script script/CCIP/DeployerMumbai.sol -vvvv --rpc-url $MUMBAI_RPC_URL --broadcast
     ```
   - For Optimism Goerli (OpGoe) Network:
     ```
     forge script script/CCIP/DeployerOpGoe.sol -vvvv --rpc-url $OPGOE_RPC_URL --broadcast
     ```

4. **Funding Vaults with LINK**:
   - Ensure each vault has enough LINK tokens for operations. You can use the following faucets:
     - [Mumbai Faucet](https://faucets.chain.link/mumbai)
     - [Optimism Goerli Faucet](https://faucets.chain.link/optimism-goerli)
     - [Fuji Faucet](https://faucets.chain.link/fuji)

5. **Executing the Main Script**:
   - To run the "fetch, collect, and execute" script:
     ```
     forge script script/CCIP/MainScript.s.sol -vvvv --rpc-url $FUJI_RPC_URL --with-gas-price 25000000000 --broadcast
     ```

### Monitoring Progress

- **Chainlink Automation Explorer**:
  - Track the progress of the "balance checker" automation on the [Chainlink Automation Explorer for Fuji](https://automation.chain.link/fuji).

- **CCIP Explorer**:
  - View cross-chain communication and transactions on the [CCIP Explorer](https://ccip.chain.link/).
