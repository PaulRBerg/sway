//! Helper functions to verify signatures.
library;

use ::address::Address;
use ::b512::B512;
use ::registers::error;
use ::hash::sha256;
use ::result::Result::{self, *};

/// The error type used when the `ec_recover` function fails.
pub enum EcRecoverError {
    UnrecoverablePublicKey: (),
}

/// Recover the public key derived from the private key used to sign a message.
/// Returns a `Result` to let the caller choose an error handling strategy.
pub fn ec_recover(signature: B512, msg_hash: b256) -> Result<B512, EcRecoverError> {
    let public_key = B512::new();
    let was_error = asm(buffer: public_key.bytes, sig: signature.bytes, hash: msg_hash) {
        eck1 buffer sig hash;
        err
    };
    // check the $err register to see if the `eck1` opcode succeeded
    if was_error == 1 {
        Err(EcRecoverError::UnrecoverablePublicKey)
    } else {
        Ok(public_key)
    }
}

/// Recover the address derived from the private key used to sign a message.
/// Returns a `Result` to let the caller choose an error handling strategy.
pub fn ec_recover_address(signature: B512, msg_hash: b256) -> Result<Address, EcRecoverError> {
    let pub_key_result = ec_recover(signature, msg_hash);

    if let Err(e) = pub_key_result {
        // propagate the error if it exists
        Err(e)
    } else {
        let pub_key = pub_key_result.unwrap();
        let address = sha256(((pub_key.bytes)[0], (pub_key.bytes)[1]));
        Ok(Address::from(address))
    }
}
