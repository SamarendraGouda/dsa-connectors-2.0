//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Fluid.
 * @dev Lending & Borrowing.
 */

import {Stores} from "../../common/stores.sol";
import {TokenInterface} from "../../common/interfaces.sol";
import {Events} from "./events.sol";
import {IVault} from "./interface.sol";

abstract contract FluidConnector is Events, Stores {
    /**
     * @dev Returns Eth address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    /**
     * @dev Deposit, borrow, payback and withdraw asset from the vault.
     * @notice Single function which handles supply, withdraw, borrow & payback
     * @param vaultAddress_ Vault address.
     * @param nftId_ NFT ID for interaction. If 0 then create new NFT/position.
     * @param newCol_ New collateral. If positive then deposit, if negative then withdraw, if 0 then do nothing
     * @param newDebt_ New debt. If positive then borrow, if negative then payback, if 0 then do nothing
     * @param to_ Address where withdraw or borrow should go. If address(0) then msg.sender
     * @param getId_ ID to retrieve NFT ID.
     * @param setId_ ID stores the NFT ID generated.
     */
    function operate(
        address vaultAddress_,
        uint256 nftId_,
        int256 newCol_,
        int256 newDebt_,
        address to_,
        uint256 getId_,
        uint256 setId_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        // todo: add max value
        nftId_ = getUint(getId_, nftId_);

        IVault vault_ = IVault(vaultAddress_);

        IVault.ConstantViews memory vaultDetails_ = vault_.constantsView();

        uint256 colEthAmount_;
        uint256 debtEthAmount_;

        if (newCol_ == type(int256).max) { // +ve max value
            
        }

        if (newCol_ > 0) {
            if (vaultDetails_.supplyToken == getEthAddr()) {
                colEthAmount_ = uint256(newCol_);
            } else {
                TokenInterface(vaultDetails_.supplyToken).approve(
                    vaultAddress_,
                    uint256(newCol_)
                );

                colEthAmount_ = 0;
            }
        }

        if (newDebt_ < 0) {
            if (vaultDetails_.borrowToken == getEthAddr()) {
                debtEthAmount_ = uint256(-1 * newDebt_);
            } else {
                TokenInterface(vaultDetails_.borrowToken).approve(
                    vaultAddress_,
                    uint256(-1 * newDebt_)
                );

                debtEthAmount_ = 0;
            }
        }

        (nftId_, newCol_, newDebt_) = vault_.operate{
            value: colEthAmount_ + debtEthAmount_
        }(nftId_, newCol_, newDebt_, to_);

        setUint(setId_, nftId_);

        _eventName = "LogOperate(address,uint256,int256,int256,address,uint256,uint256)";
        _eventParam = abi.encode(
            vaultAddress_,
            nftId_,
            newCol_,
            newDebt_,
            to_,
            getId_,
            setId_
        );
    }
}

contract ConnectV2Fluid is FluidConnector {
    string public constant name = "Fluid-v1.0";
}
