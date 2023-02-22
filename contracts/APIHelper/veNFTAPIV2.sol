// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../libraries/Math.sol";
import "../interfaces/IBribeAPI.sol";
import "../interfaces/IWrappedBribeFactory.sol";
import "../interfaces/IGaugeAPI.sol";
import "../interfaces/IGaugeFactoryV3.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IMinter.sol";
import "../interfaces/IPair.sol";
import "../interfaces/IPairFactory.sol";
import "../interfaces/IVoter.sol";
import "../interfaces/IVotingEscrow.sol";
import "../interfaces/IRewardsDistributor.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IPairAPI {
    /*  ╔══════════════════════════════╗
        ║            Struct            ║
        ╚══════════════════════════════╝ */
    struct pairInfo {
        // pair info
        address pair_address; // pair contract address
        string symbol; // pair symbol
        string name; // pair name
        uint256 decimals; // pair decimals
        bool stable; // pair pool type (stable = false, means it's a variable type of pool)
        uint256 total_supply; // pair tokens supply
        // token pair info
        address token0; // pair 1st token address
        string token0_symbol; // pair 1st token symbol
        uint256 token0_decimals; // pair 1st token decimals
        uint256 reserve0; // pair 1st token reserves (nr. of tokens in the contract)
        uint256 claimable0; // claimable 1st token from fees (for unstaked positions)
        address token1; // pair 2nd token address
        string token1_symbol; // pair 2nd token symbol
        uint256 token1_decimals; // pair 2nd token decimals
        uint256 reserve1; // pair 2nd token reserves (nr. of tokens in the contract)
        uint256 claimable1; // claimable 2nd token from fees (for unstaked positions)
        // pairs gauge
        address gauge; // pair gauge address
        uint256 gauge_total_supply; // pair staked tokens (less/eq than/to pair total supply)
        address fee; // pair fees contract address
        address bribe; // pair bribes contract address
        uint256 emissions; // pair emissions (per second)
        address emissions_token; // pair emissions token address
        uint256 emissions_token_decimals; // pair emissions token decimals
        // User deposit
        uint256 account_lp_balance; // account LP tokens balance
        uint256 account_token0_balance; // account 1st token balance
        uint256 account_token1_balance; // account 2nd token balance
        uint256 account_gauge_balance; // account pair staked in gauge balance
        uint256 account_gauge_earned; // account earned emissions for this pair
    }

    function getPair(address _pair, address _account)
        external
        view
        returns (pairInfo memory _pairInfo);

    function pair_factory() external view returns (address);
}

contract veNFTAPI is OwnableUpgradeable {
    struct pairVotes {
        address pair;
        uint256 weight;
    }

    struct veNFT {
        uint8 decimals;
        bool voted;
        uint256 attachments;
        uint256 id;
        uint128 amount;
        uint256 voting_amount;
        uint256 rebase_amount;
        uint256 lockEnd;
        uint256 vote_ts;
        pairVotes[] votes;
        address account;
        address token;
        string tokenSymbol;
        uint256 tokenDecimals;
    }

    struct Reward {
        uint256 id;
        uint256 amount;
        uint8 decimals;
        address pair;
        address token;
        address fee;
        address bribe;
        string symbol;
    }

    uint256 public constant MAX_RESULTS = 1000;
    uint256 public constant MAX_PAIRS = 30;

    IVoter public voter;
    address public underlyingToken;

    mapping(address => bool) public notReward;

    IVotingEscrow public ve;
    IRewardsDistributor public rewardDisitributor;

    address public pairAPI;
    IPairFactory public pairFactory;

    struct AllPairRewards {
        Reward[] rewards;
    }

    /*  ╔══════════════════════════════╗
        ║          INITIALIZER         ║
        ╚══════════════════════════════╝ */
    function initialize(
        address _voter,
        address _rewarddistro,
        address _pairApi,
        address _pairFactory
    ) public initializer {
        __Ownable_init();

        pairAPI = _pairApi;
        voter = IVoter(_voter);
        rewardDisitributor = IRewardsDistributor(_rewarddistro);

        require(rewardDisitributor.votingEscrow() == voter._ve(), "ve!=ve");

        ve = IVotingEscrow(rewardDisitributor.votingEscrow());
        underlyingToken = IVotingEscrow(ve).token();

        pairFactory = IPairFactory(_pairFactory);
        notReward[address(0xF0308D005717858756ACAa6B3DCd4D0De4A1ca54)] = true;
    }

    /*  ╔══════════════════════════════╗
        ║       ADMIN UTILITIES        ║
        ╚══════════════════════════════╝ */

    function setVoter(address _voter) external onlyOwner {
        voter = IVoter(_voter);
    }

    function setRewardDistro(address _rewarddistro) external onlyOwner {
        rewardDisitributor = IRewardsDistributor(_rewarddistro);
        require(rewardDisitributor.votingEscrow() == voter._ve(), "ve!=ve");

        ve = IVotingEscrow(rewardDisitributor.votingEscrow());
        underlyingToken = IVotingEscrow(ve).token();
    }

    function setPairAPI(address _pairApi) external onlyOwner {
        pairAPI = _pairApi;
    }

    function setPairFactory(address _pairFactory) external onlyOwner {
        pairFactory = IPairFactory(_pairFactory);
    }

    /*  ╔══════════════════════════════╗
        ║     INTERNAL UTILITIES       ║
        ╚══════════════════════════════╝ */

    function _getNFTFromId(uint256 id, address _owner)
        internal
        view
        returns (veNFT memory venft)
    {
        if (_owner == address(0)) {
            return venft;
        }

        uint256 _totalPoolVotes = voter.poolVoteLength(id);
        pairVotes[] memory votes = new pairVotes[](_totalPoolVotes);

        IVotingEscrow.LockedBalance memory _lockedBalance;
        _lockedBalance = ve.locked(id);

        uint256 k;
        uint256 _poolWeight;
        address _votedPair;

        for (k = 0; k < _totalPoolVotes; k++) {
            _votedPair = voter.poolVote(id, k);
            if (_votedPair == address(0)) {
                break;
            }
            _poolWeight = voter.votes(id, _votedPair);
            votes[k].pair = _votedPair;
            votes[k].weight = _poolWeight;
        }

        venft.id = id;
        venft.account = _owner;
        venft.decimals = ve.decimals();
        venft.amount = uint128(_lockedBalance.amount);
        venft.voting_amount = ve.balanceOfNFT(id);
        venft.rebase_amount = rewardDisitributor.claimable(id);
        venft.lockEnd = _lockedBalance.end;
        venft.vote_ts = voter.lastVoted(id);
        venft.votes = votes;
        venft.token = ve.token();
        venft.tokenSymbol = IERC20(ve.token()).symbol();
        venft.tokenDecimals = IERC20(ve.token()).decimals();
        venft.voted = ve.voted(id);
        venft.attachments = ve.attachments(id);
    }

    function _pairReward(address _pair, uint256 id)
        internal
        view
        returns (Reward[] memory _reward)
    {
        if (_pair == address(0)) {
            return _reward;
        }

        IPairAPI.pairInfo memory _pairApi = IPairAPI(pairAPI).getPair(
            _pair,
            address(0)
        );

        address wrappedBribe = _pairApi.bribe;

        uint256 totBribeTokens = (wrappedBribe == address(0))
            ? 0
            : IBribeAPI(wrappedBribe).rewardsListLength();

        uint256 bribeAmount;

        _reward = new Reward[](2 + totBribeTokens);

        address _gauge = (voter.gauges(_pair));

        if (_gauge == address(0)) {
            return _reward;
        }

        (, , , , , address t0, address t1) = IPair(_pair).metadata();
        uint256 _feeToken0 = IBribeAPI(_pairApi.fee).earned(id, t0);
        uint256 _feeToken1 = IBribeAPI(_pairApi.fee).earned(id, t1);

        if (_feeToken0 > 0) {
            _reward[0] = Reward({
                id: id,
                pair: _pair,
                amount: _feeToken0,
                token: t0,
                symbol: IERC20(t0).symbol(),
                decimals: IERC20(t0).decimals(),
                fee: voter.internal_bribes(address(_gauge)),
                bribe: address(0)
            });
        }

        if (_feeToken1 > 0) {
            _reward[1] = Reward({
                id: id,
                pair: _pair,
                amount: _feeToken1,
                token: t1,
                symbol: IERC20(t1).symbol(),
                decimals: IERC20(t1).decimals(),
                fee: voter.internal_bribes(address(_gauge)),
                bribe: address(0)
            });
        }

        //wrapped bribe point to Bribes.sol (ext bribe)
        if (wrappedBribe == address(0)) {
            return _reward;
        }

        uint256 k = 0;
        address _token;

        for (k; k < totBribeTokens; k++) {
            _token = IBribeAPI(wrappedBribe).rewardTokens(k);
            bribeAmount = IBribeAPI(wrappedBribe).earned(id, _token);
            if (!notReward[_token]) {
                _reward[2 + k] = Reward({
                    id: id,
                    pair: _pair,
                    amount: bribeAmount,
                    token: _token,
                    symbol: IERC20(_token).symbol(),
                    decimals: IERC20(_token).decimals(),
                    fee: address(0),
                    bribe: wrappedBribe
                });
            }
        }

        return _reward;
    }

    /*  ╔══════════════════════════════╗
        ║            GETTER            ║
        ╚══════════════════════════════╝ */
    function getAllNFT(uint256 _amounts, uint256 _offset)
        external
        view
        returns (veNFT[] memory _veNFT)
    {
        require(_amounts <= MAX_RESULTS, "too many nfts");
        _veNFT = new veNFT[](_amounts);

        uint256 i = _offset;
        address _owner;

        for (i; i < _offset + _amounts; i++) {
            _owner = ve.ownerOf(i);
            // if id_i has owner read data
            if (_owner != address(0)) {
                _veNFT[i - _offset] = _getNFTFromId(i, _owner);
            }
        }
    }

    function getNFTFromId(uint256 id) external view returns (veNFT memory) {
        return _getNFTFromId(id, ve.ownerOf(id));
    }

    function getNFTFromAddress(address _user)
        external
        view
        returns (veNFT[] memory venft)
    {
        uint256 i = 0;
        uint256 _id;
        uint256 totNFTs = ve.balanceOf(_user);

        venft = new veNFT[](totNFTs);

        for (i; i < totNFTs; i++) {
            _id = ve.tokenOfOwnerByIndex(_user, i);
            if (_id != 0) {
                venft[i] = _getNFTFromId(_id, _user);
            }
        }
    }

    function allPairRewards(
        uint256 _amount,
        uint256 _offset,
        uint256 id
    ) external view returns (AllPairRewards[] memory rewards) {
        rewards = new AllPairRewards[](MAX_PAIRS);

        uint256 totalPairs = pairFactory.allPairsLength();

        uint256 i = _offset;
        address _pair;
        for (i; i < _offset + _amount; i++) {
            if (i >= totalPairs) {
                break;
            }
            _pair = pairFactory.allPairs(i);
            rewards[i].rewards = _pairReward(_pair, id);
        }
    }

    function singlePairReward(uint256 id, address _pair)
        external
        view
        returns (Reward[] memory _reward)
    {
        return _pairReward(_pair, id);
    }
}
