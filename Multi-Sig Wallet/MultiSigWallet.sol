// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract MultiSigWallet {


    // events
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
    // events

    address[] public owners;
    mapping (address => bool) isOwner;
    uint public numConfirmationsRequired;


    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    // Mapping total number of booleans (either True or False) from owners
    mapping (uint => mapping (address => bool)) public isConfirmed;

    // keeping the record of transactions
    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Invalid owner");
        _;
    }

    // checks whether the transaction exists
    modifier txnExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }
     // checks whether the proposed transaction is already executed
    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor (address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "Owners Reqd");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= owners.length, "Confirmations and owners are invalid");
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require (owner != address(0), "Owner invalid");
            require(!isOwner[owner], "owner already exists");
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }


    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint _txIndex) public onlyOwner

    txnExists(_txIndex)
    notExecuted(_txIndex)
    notConfirmed(_txIndex)  
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint _txIndex)
        public
        onlyOwner
        txnExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}


