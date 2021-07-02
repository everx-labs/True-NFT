pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './resolvers/NftResolver.sol';
import './resolvers/NftDataResolver.sol';

import './interfaces/INft.sol';
import './interfaces/INftData.sol';

struct OnwerChange {
    address addrNftData;
    address addrTo;
}

contract NftRoot is NftResolver, NftDataResolver {
    uint256 _totalNfts;
    // addtNft => OnwerChange
    mapping(address => OnwerChange) _pendingOwners;

    constructor(TvmCell codeNft, TvmCell codeNftData) public {
        tvm.accept();
        _codeNft = codeNft;
        _codeNftData = codeNftData;
    }

    function mintNft() public {
        TvmCell codeNftData = _buildNftDataCode(address(this));
        TvmCell stateNftData = _buildNftDataState(codeNftData, _totalNfts);
        address addrNftData = new NftData{stateInit: stateNftData, value: 0.4 ton}(msg.sender, msg.sender);

        TvmCell codeNft = _buildNftCode(address(this), msg.sender);
        TvmCell stateNft = _buildNftState(codeNft, addrNftData);
        new Nft{stateInit: stateNft, value: 0.4 ton}();
    }

    function transferOwnership(address addrNft, address addrNftData, address addrTo) public {
        require(resolveNft(address(this), addrNftData, msg.sender) == addrNft);
        _pendingOwners[addrNft] = OnwerChange(addrNftData, addrTo);
        INft(addrNft).destruct();
    }

    receive() external {
        optional(OnwerChange) optPendingOwner = _pendingOwners.fetch(msg.sender);
        if(optPendingOwner.hasValue()) {
            OnwerChange pendingOwner = optPendingOwner.get();
            INftData(pendingOwner.addrNftData).setOwner(pendingOwner.addrTo);

            delete _pendingOwners[msg.sender];

            TvmCell codeNft = _buildNftCode(address(this), pendingOwner.addrTo);
            TvmCell stateNft = _buildNftState(codeNft, pendingOwner.addrNftData);
            new Nft{stateInit: stateNft, value: 0.3 ton}();
        }
    }
}