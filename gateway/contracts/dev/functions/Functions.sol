// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {CBOR, Buffer} from "../vendor/solidity-cborutils/2.0.0/CBOR.sol";

/**
 * @title Library for Chainlink Functions
 */
library Functions {
    uint256 internal constant DEFAULT_BUFFER_SIZE = 256;

    using CBOR for Buffer.buffer;

    enum Location {
        Inline,
        Remote
    }

    enum CodeLanguage {
        JavaScript
        // In future version we may add other languages
    }

    struct Request {
        Location codeLocation;
        Location secretsLocation;
        CodeLanguage language;
        bytes32 serviceName;
        string functionName;
        bytes secrets; // Encrypted secrets blob for Location.Inline or url for Location.Remote
        string[] args;
    }
    struct Response {
        bytes response;
        bytes err;
    }

    error EmptyFunctionName();
    error EmptyUrl();
    error EmptySecrets();
    error EmptyArgs();
    error NoInlineSecrets();
    error EmptyArg();

    /**
     * @notice Encodes a Request to CBOR encoded bytes
     * @param self The request to encode
     * @return CBOR encoded bytes
     */
    function encodeCBOR(
        Request memory self
    ) internal pure returns (bytes memory) {
        CBOR.CBORBuffer memory buffer;
        Buffer.init(buffer.buf, DEFAULT_BUFFER_SIZE);

        CBOR.writeString(buffer, "codeLocation");
        CBOR.writeUInt256(buffer, uint256(self.codeLocation));

        CBOR.writeString(buffer, "language");
        CBOR.writeUInt256(buffer, uint256(self.language));

        CBOR.writeString(buffer, "serviceName");
        CBOR.writeUInt256(buffer, uint256(self.serviceName));

        CBOR.writeString(buffer, "functionName");
        CBOR.writeString(buffer, self.functionName);

        if (self.args.length > 0) {
            CBOR.writeString(buffer, "args");
            CBOR.startArray(buffer);
            for (uint256 i = 0; i < self.args.length; i++) {
                CBOR.writeString(buffer, self.args[i]);
            }
            CBOR.endSequence(buffer);
        }

        if (self.secrets.length > 0) {
            if (self.secretsLocation == Location.Inline) {
                revert NoInlineSecrets();
            }
            CBOR.writeString(buffer, "secretsLocation");
            CBOR.writeUInt256(buffer, uint256(self.secretsLocation));
            CBOR.writeString(buffer, "secrets");
            CBOR.writeBytes(buffer, self.secrets);
        }

        return buffer.buf.buf;
    }

    /**
     * @notice Initializes a Chainlink Functions Request
     * @dev Sets the codeLocation and code on the request
     * @param self The uninitialized request
     * @param location The user provided source code location
     * @param language The programming language of the user code
     * @param functionName The user provided functionName code or a url
     */
    function initializeRequest(
        Request memory self,
        Location location,
        CodeLanguage language,
        string memory functionName,
        bytes32 name
    ) internal pure {
        if (bytes(functionName).length == 0) revert EmptyFunctionName();

        self.codeLocation = location;
        self.language = language;
        self.functionName = functionName;
        self.serviceName = name;
    }

    function initializeResponse(
        Response memory self,
        bytes memory resp,
        bytes memory err
    ) internal pure {
        if (resp.length == 0) revert EmptyArg();
        if (err.length == 0) revert EmptyArg();

        self.response = resp;
        self.err = err;
    }

    function encodeResponse(
        Response memory self
    ) internal pure returns (bytes memory) {
        CBOR.CBORBuffer memory buffer;
        Buffer.init(buffer.buf, DEFAULT_BUFFER_SIZE);

        if (self.response.length > 0) {
            CBOR.writeString(buffer, "response");
            CBOR.writeBytes(buffer, self.response);
        }
        if (self.err.length > 0) {
            CBOR.writeString(buffer, "err");
            CBOR.writeBytes(buffer, self.err);
        }

        return buffer.buf.buf;
    }

    struct FunctionRecord {
        string name;
        string language;
        string codeFrom;
        bool doUpdate;
        uint256 version;
        string[] envVars;
    }

    function encodeFunctionRecord(
        FunctionRecord memory self
    ) internal pure returns (bytes memory) {
        CBOR.CBORBuffer memory buffer;
        Buffer.init(buffer.buf, DEFAULT_BUFFER_SIZE);

        CBOR.writeString(buffer, "name");
        CBOR.writeString(buffer, self.name);

        CBOR.writeString(buffer, "language");
        CBOR.writeString(buffer, self.language);

        CBOR.writeString(buffer, "codeFrom");
        CBOR.writeString(buffer, self.codeFrom);

        CBOR.writeString(buffer, "version");
        CBOR.writeUInt256(buffer, uint256(self.version));

        CBOR.writeString(buffer, "doUpdate");
        CBOR.writeBool(buffer, self.doUpdate);

        if (self.envVars.length > 0) {
            CBOR.writeString(buffer, "envVars");
            CBOR.startArray(buffer);
            for (uint256 i = 0; i < self.envVars.length; i++) {
                CBOR.writeString(buffer, self.envVars[i]);
            }
            CBOR.endSequence(buffer);
        }

        return buffer.buf.buf;
    }

    /**
     * @notice Initializes a  Functions Request
     * @dev Simplified version of initializeRequest for PoC
     * @param self The uninitialized request
     * @param javaScriptSource The user provided JS code (must not be empty)
     */
    function initializeRequestForInlineJavaScript(
        Request memory self,
        string memory javaScriptSource
    ) internal pure {
        initializeRequest(
            self,
            Location.Inline,
            CodeLanguage.JavaScript,
            javaScriptSource,
            bytes32(0x0)
        );
    }

    /**
     * @notice Adds Remote user encrypted secrets to a Request
     * @param self The initialized request
     * @param encryptedSecretsURLs Encrypted comma-separated string of URLs pointing to off-chain secrets
     */
    function addRemoteSecrets(
        Request memory self,
        bytes memory encryptedSecretsURLs
    ) internal pure {
        if (encryptedSecretsURLs.length == 0) revert EmptySecrets();

        self.secretsLocation = Location.Remote;
        self.secrets = encryptedSecretsURLs;
    }

    /**
     * @notice Adds args for the user run function
     * @param self The initialized request
     * @param args The array of args (must not be empty)
     */
    function addArgs(Request memory self, string[] memory args) internal pure {
        if (args.length == 0) revert EmptyArgs();

        self.args = args;
    }
}
