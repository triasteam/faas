// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Functions, FunctionsClient} from "./dev/functions/FunctionsClient.sol";
import "./dev/functions/registry.sol";
import "./dev/functions/BaseManagerImpl.sol";

/**
 * @title Functions Consumer contract
 * @notice This contract is a demonstration of using Functions.
 * @notice NOT FOR PRODUCTION USE
 */
contract BlogConsumer is FunctionsClient {
    using Functions for Functions.Request;

    bytes32 public latestRequestId;
    bytes public latestResponse;
    bytes public latestError;

    event FuncResponse(bytes32 indexed requestId, bytes result, bytes err);
    event NewBlog(uint256 indexed blogId, address author);
    

    mapping( uint256 => bytes) blogContent;
    mapping( address => uint256[])  blogOwnerIndex;
    mapping( uint256 => address ) blogIndex;
    uint256[] public blogSlice;

    error ArgsExceptions(string[]);
    error BlogOverflow(uint256 blogRealLength, uint expectBeginLength);
 
    constructor(address oracle,Registry _reg)FunctionsClient(oracle,_reg)  {}
    /**
     * @notice Send a simple request, 
     *
     * @param source JavaScript source code
     * @param secrets Encrypted secrets payload
     * @param args List of arguments accessible from within the source code
     * @return Functions request ID
    */
    function executeRequest(
        bytes32 name,
        string calldata source,
        bytes calldata secrets,
        string[] calldata args
    ) public returns (bytes32) {
        
        Functions.Request memory req;
        req.initializeRequest(Functions.Location.Inline, Functions.CodeLanguage.JavaScript, source, name);

        if (secrets.length > 0) {
            req.addRemoteSecrets(secrets);
        }

        if (args.length > 0) {
            req.addArgs(args);
        }

        bytes32 assignedReqID = sendRequest(req);

        if (args.length < 2) {
            revert ArgsExceptions(args);
        }
        uint256 blogId=uint256(assignedReqID);
        blogContent[blogId]=bytes(args[1]);
        blogOwnerIndex[msg.sender].push(blogId);
        blogIndex[blogId]=msg.sender;
        emit NewBlog(blogId, msg.sender);
        latestRequestId = assignedReqID;
        
        return assignedReqID;
    }
    /**
     * @notice Callback that is invoked once the DON has resolved the request or hit an error
     *
     * @param requestId The request ID, returned by sendRequest()
     * @param response Aggregated response from the user code
     * @param err Aggregated error from the user code or from the execution pipeline
     * Either response or error parameter will be set, but never both
    */
    function fulfillRequest(
        bytes32 requestId, bytes memory response, bytes memory err
    ) internal override {
        latestResponse = response;
        latestError = err;
        emit FuncResponse(requestId, response, err);
    }

    function getBlogContent(bytes32 blogId)public view returns( bytes memory){

        return blogContent[uint256(blogId)];
    }

    function getBlogsWithCounts(address author, uint beginIndex, uint counts)public returns(uint256[] memory){
        uint blogLength = blogOwnerIndex[author].length;
        if (blogLength<beginIndex && beginIndex>0){
            revert BlogOverflow(blogLength,beginIndex);
        }
        delete blogSlice;
        for(uint256 i = beginIndex; i < blogLength && i - beginIndex <= counts; i++){
           blogSlice.push(blogOwnerIndex[author][i-1]);
        }
        return blogSlice;
    }

    function getBlogs(address author)public view returns(uint256[] memory){
       
        return blogOwnerIndex[author];
    }

    function BlogOwnerOf(bytes32 blogId)public view returns(address){
        return blogIndex[uint256(blogId)];
    }
}
