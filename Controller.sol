pragma solidity 0.5.16;

import "./library/Address.sol";
import "./library/SafeMath.sol";
import "./library/SafeERC20.sol";

import "./interface/IERC20.sol";
import "./interface/IController.sol";
import "./interface/IBridgeStrategy.sol";
import "./interface/IRewardPool.sol";
import "./interface/IFeeRewardForwarder.sol";
import "./interface/IHardRewards.sol";
import "./interface/IApiConsumer.sol";
import "./interface/IMainStrategy.sol";
import "./interface/IVault.sol";

import "./Storage.sol";

contract Governable {

    Storage public store;

    constructor(address _store) public {
        require(_store != address(0), "new storage shouldn't be empty");
        store = Storage(_store);
    }

    modifier onlyGovernance() {
        require(store.isGovernance(msg.sender), "Not governance");
        _;
    }

    function setStorage(address _store) public onlyGovernance {
        require(_store != address(0), "new storage shouldn't be empty");
        store = Storage(_store);
    }

    function governance() public view returns (address) {
        return store.governance();
    }
}

contract Controller is IController, Governable {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    // external parties
    address public rewardPool;

    mapping(address => bool) public greyList;

    // All vaults that we have
    mapping(address => bool) public vaults;
    address public oracleContract;
    mapping(address => bool) public isRequestFutureVault;
    // Rewards for hard work. Nullable.
    IHardRewards public hardRewards;

    uint256 public constant profitSharingNumerator = 5;
    uint256 public constant profitSharingDenominator = 100;

    event SharePriceChangeLog(
        address indexed vault,
        address indexed strategy,
        uint256 oldSharePrice,
        uint256 newSharePrice,
        uint256 timestamp
    );

    modifier validVault(address _vault){
        require(vaults[_vault], "vault does not exist");
        _;
    }

    mapping(address => bool) public hardWorkers;

    modifier onlyHardWorkerOrGovernance() {
        require(hardWorkers[msg.sender] || (msg.sender == governance()), "only hard worker can call this");
        _;
    }

    constructor(address _storage)Governable(_storage) public {
    }

    function setOracleAddress(address _address) external onlyGovernance {
        oracleContract = _address;
    }

    function setRewardPool(address _rewardPool) external onlyGovernance {
        rewardPool = _rewardPool;
    }

    function addHardWorker(address _worker) external onlyGovernance {
        require(_worker != address(0), "_worker must be defined");
        hardWorkers[_worker] = true;
    }

    function removeHardWorker(address _worker) external onlyGovernance {
        require(_worker != address(0), "_worker must be defined");
        hardWorkers[_worker] = false;
    }

    function hasVault(address _vault) external returns (bool) {
        return vaults[_vault];
    }

    // Only smart contracts will be affected by the greyList.
    function addToGreyList(address _target) external onlyGovernance {
        greyList[_target] = true;
    }

    function removeFromGreyList(address _target) external onlyGovernance {
        greyList[_target] = false;
    }


    function onlyOracleOrGovernance() private view {
        require((oracleContract != address(0) && msg.sender == oracleContract) || (store.isGovernance(msg.sender)), "Invalid oracle");
    }

    function salvage(address _token, uint256 _amount) external onlyGovernance {
        IERC20(_token).safeTransfer(governance(), _amount);
    }

    function notifyFee(address underlying, uint256 fee) external {
        if (fee > 0) {
            if (rewardPool != address(0)) {
                IERC20(underlying).safeTransferFrom(msg.sender, rewardPool, fee);
            }
            else {
                IERC20(underlying).safeTransferFrom(msg.sender, address(this), fee);
            }
        }
    }

    function setNewWeight(bytes calldata data) external {
        onlyOracleOrGovernance();
        (address _vault, address[] memory _strategies, uint256[] memory _weights) = abi.decode(data, (address, address[], uint256[]));
        require(_vault != address(0), "new vault shouldn't be empty");
        require(vaults[_vault], "vault do not exists");
        IMainStrategy(IVault(_vault).strategy()).setWeight(_strategies, _weights);
        isRequestFutureVault[_vault] = false;

    }

    function requestFutureWeights(address _vault, address _requestConsumer) external onlyHardWorkerOrGovernance {
        require(_vault != address(0), "new vault shouldn't be empty");
        require(vaults[_vault], "vault do not exists");
        require(!isRequestFutureVault[_vault], "Vault is being request future strategy");
        bytes memory data = abi.encode(_vault, IVault(_vault).investedTokenAmount(), IVault(_vault).availableToInvestOut(), IVault(_vault).underlying());
        IApiConsumer(_requestConsumer).requestData(
            data,
            this.setNewWeight.selector,
            address(this)
        );
        isRequestFutureVault[_vault] = true;

    }

    function cancelRequestFutureStragety(address _vault) external onlyHardWorkerOrGovernance {
        require(_vault != address(0), "new vault shouldn't be empty");
        require(vaults[_vault], "vault do not exists");
        //        IVault(_vault).finalizeStrategyUpdate();
        isRequestFutureVault[_vault] = false;
    }

    function addVaultAndStrategy(address _vault, address[] calldata _strategies, address[] calldata _bridgeStrategies, uint256[] calldata _weights) external onlyGovernance {
        require(_vault != address(0), "new vault shouldn't be empty");
        require(!vaults[_vault], "vault already exists");
        IMainStrategy(IVault(_vault).strategy()).addStrategy(_strategies, _bridgeStrategies, _weights);
        vaults[_vault] = true;
    }

    function doHardWork(address _vault) external onlyHardWorkerOrGovernance validVault(_vault) {
        uint256 oldSharePrice = IVault(_vault).getPricePerFullShare();
        IVault(_vault).doHardWork();
        emit SharePriceChangeLog(
            _vault,
            IVault(_vault).strategy(),
            oldSharePrice,
            IVault(_vault).getPricePerFullShare(),
            block.timestamp
        );
    }

    //    function rebalance(address _vault) external onlyHardWorkerOrGovernance validVault(_vault) {
    //        IVault(_vault).rebalance();
    //    }

}