package cbor

import (
	"encoding/hex"

	"github.com/pkg/errors"
)

// TryParseHex parses the given hex string to bytes,
// it can return error if the hex string is invalid.
// Follows the semantic of ethereum's FromHex.
func TryParseHex(s string) (b []byte, err error) {
	if !HasHexPrefix(s) {
		err = errors.New("hex string must have 0x prefix")
	} else {
		s = s[2:]
		if len(s)%2 == 1 {
			s = "0" + s
		}
		b, err = hex.DecodeString(s)
	}
	return
}

// HasHexPrefix returns true if the string starts with 0x.
func HasHexPrefix(str string) bool {
	return len(str) >= 2 && str[0] == '0' && (str[1] == 'x' || str[1] == 'X')
}
