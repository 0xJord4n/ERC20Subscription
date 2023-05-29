// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract SigUtils {
    bytes32 internal DOMAIN_SEPARATOR;

    constructor(bytes32 _DOMAIN_SEPARATOR) {
        DOMAIN_SEPARATOR = _DOMAIN_SEPARATOR;
    }

    bytes32 public constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint32 recurrenceInterval,uint48 approveUntil,uint256 nonce,uint256 deadline)"
    );

    struct Permit {
        address owner;
        address spender;
        uint256 value;
        uint32 reccurenceInterval;
        uint48 approveUntil;
        uint256 nonce;
        uint256 deadline;
    }

    // computes the hash of a permit
    function getStructHash(Permit memory _permit) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                _permit.owner,
                _permit.spender,
                _permit.value,
                _permit.reccurenceInterval,
                _permit.approveUntil,
                _permit.nonce,
                _permit.deadline
            )
        );
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(Permit memory _permit) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, getStructHash(_permit)));
    }
}
