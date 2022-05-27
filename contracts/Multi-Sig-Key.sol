pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MultiSigTreasury is ERC1155{
    uint KEYS =0;
    uint public TotalTransactions=0;
    uint public VotesNeededToPass;

    mapping(uint => KeyListings) keys;
    mapping(string => VoteOnTransaction) vote;
    mapping(uint => MultiSigTransaction) MSTrans;
    
    //list Keys
    struct KeyListings{
        uint count;
        bool exist;
    }
    //cast vote for transaction
    struct VoteOnTransaction{
        uint Key;
        bool status;
        bool exist;
    }
    struct MultiSigTransaction{
        uint amount;
        address toAddress;
        string topic;
        string messege;
        bool status;
        uint pass;
        uint fail;
        uint voteCount;
        bool exist;
    }
    //Launch Contract and Keys
    constructor(uint _totalKeys, uint _VotesNeededToPass,string memory URI)ERC1155(URI){
        require(_VotesNeededToPass <= _totalKeys);
        KEYS =_totalKeys;
        VotesNeededToPass = _VotesNeededToPass;
        uint countKeys;
        for(countKeys=0; countKeys < _totalKeys; countKeys++){
            keys[countKeys] = KeyListings(countKeys,true);
            _mint(msg.sender, countKeys, 1, "");
        }
    }
    //modifier checks to see if user has a key before executing the function
    modifier CheckKeys{
        (bool keyStatus,uint keyNumb) = checkTokens(msg.sender);
        require(keyStatus == true);
        _;
    }
    //internal function checks to see if user has key
    function checkTokens(address _user) internal returns(bool,uint){
        uint i;
        for(i=0; i <= KEYS; i++){
            if(balanceOf(_user,i) > 0){
                return (true,i);
            } else if(i == KEYS){
                return (false,i);
            }
        }       
    }
    //check vote summition total
    function checkTotal(uint _TransactionNumber) internal returns(bool){
        //set up voting count
        if(MSTrans[_TransactionNumber].pass >= VotesNeededToPass){
            executeTransaction(_TransactionNumber);
            return true;
        } else {
            return false;
        }
    }
    //checks the voting status of a particular vote on a transactions
    function checkVote(string memory _keyNumb, string memory _transNumb) public CheckKeys returns(uint,bool){
        string memory checkStatus;
        checkStatus = string(abi.encodePacked(_transNumb,"-",_keyNumb));
        return (vote[checkStatus].Key,vote[checkStatus].status);
    }
    //view previouse & pending transactions
    function viewTransaction(uint _transactionNumb) public CheckKeys returns(uint,address,string memory,string memory,bool,uint){
        require(_transactionNumb <= TotalTransactions, " _transactionNumb cant exceed the totalTransactions");
        return (MSTrans[_transactionNumb].amount ,MSTrans[_transactionNumb].toAddress ,MSTrans[_transactionNumb].topic ,MSTrans[_transactionNumb].messege,MSTrans[_transactionNumb].status ,MSTrans[_transactionNumb].pass);
    }
    //make a submittion to move funds to the contract
    function submitTransaction(uint _ammount, address _toAddress,string memory _topic,string memory _messege) public CheckKeys returns(bool){
        MSTrans[TotalTransactions] = MultiSigTransaction(_ammount,_toAddress,_topic,_messege,false,0,0,0,true);
        TotalTransactions++;
        return true;
    }
    //key holders can cast votes as a key for a transaction
    function confirmTransaction(uint _TransactionNumber, bool _vote,uint _keyNumb) public CheckKeys returns(uint,uint){
        require(MSTrans[_TransactionNumber].status == false, "Contract Transaction Completed...no futher confrimation votes can be cast");
        string memory castVote;
        castVote = string(abi.encodePacked(_TransactionNumber,"-",_keyNumb));
        
        require(vote[castVote].exist == false, "vote has been cast already");
        
        vote[castVote] = VoteOnTransaction(_keyNumb,_vote,true);
        
        if(_vote== true){
            MSTrans[_TransactionNumber].pass++;
        }else{
            MSTrans[_TransactionNumber].fail++;
        }
        checkTotal(_TransactionNumber);
        return (MSTrans[_TransactionNumber].pass,MSTrans[_TransactionNumber].fail);
    }
    //Executes payment ticket after parties have voted on it
    function executeTransaction(uint _TransactionNumber) internal returns(bool){
        address _address = MSTrans[_TransactionNumber].toAddress;
        MSTrans[_TransactionNumber].status = true;
        payable(_address).transfer(MSTrans[_TransactionNumber].amount);
        return true;
    }
    //remove vote if transaction hasent been confirmed yet
    function revokeConfirmation(uint _TransactionNumber) public CheckKeys returns(bool){
        require(MSTrans[_TransactionNumber].status ==false && MSTrans[_TransactionNumber].exist == true ,"Transaction already confirmed");
    }
}