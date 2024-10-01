pragma solidity ^0.5.16;

contract Hostel{
    address payable tenant;
    address payable landlord;

    uint public no_of_rooms = 0;
    uint public no_of_agreement = 0;
    uint public no_of_rent = 0;

    struct Room{
        uint roomid;
        uint agreementid;
        string roomname;
        string roomaddress;
        uint rent_per_month;
        uint securityDeposit;
        uint timestamp;
        bool vacant;
        address payable landlord;
        address  payable currentTenant;
    }

    mapping(uint => Room) public Room_by_No;

    struct RoomAgreement{
        uint roomid;
        uint agreementid;
        string roomname;
        string roomaddress;
        uint rent_per_month;
        uint securityDeposit;
        uint timestamp;
        bool vacant;
        address payable landlord;
        address  payable currentTenant;
    }

    mapping(uint => RoomAgreement) public RoomAgreement_by_No;

    struct Rent{
        uint roomid;
        uint agreementid;
        string roomname;
        string roomaddress;
        uint rent_per_month;
        uint securityDeposit;
        uint timestamp;
        bool vacant;
        address payable landlord;
        address  payable currentTenant;
    }

    mapping(uint => Rent) public Rent_by_No;

    modifier onlyLandLord(uint _index){
        require(msg.sender == Room_by_No[_index].landlord, "Only landlord can access this");
        _;
    }

     modifier notLandLord(uint _index){
        require(msg.sender == Room_by_No[_index].landlord, "Only Tenant can access this");
        _;
    }

     modifier OnlyWhileVacant(uint _index){
        require( Room_by_No[_index].vacant == true, "Room is currently Occupied");
        _;
    }

     modifier enoughRent(uint _index){
        require(msg.value >= uint(Room_by_No[_index].rent_per_month), "Not enought Ether in your wallet");
        _;
    }

     modifier enoughAgreementfee(uint _index){
        require(msg.value >= uint(uint(Room_by_No[_index].rent_per_month) + uint(Room_by_No[_index].securityDeposit)), "Only landlord can access this");
        _;
    }

     modifier sameTenant(uint _index){
        require(msg.sender == Room_by_No[_index].currentTenant, "No previous agreement found with you and the landlord");
        _;
    }

     modifier AgreementTimesLeft(uint _index){
        uint _AgreementNo = Room_by_No[_index].agreementid;
        uint time = RoomAgreement_by_No[_AgreementNo].timestamp + RoomAgreement_by_No[_AgreementNo].lockIn;
        require( now < time, "Agreement already ended");
        _;
    }


     modifier AgreementTimesUp(uint _index){
        uint _AgreementNo = Room_by_No[_index].agreementid;
        uint time = RoomAgreement_by_No[_AgreementNo].timestamp + RoomAgreement_by_No[_AgreementNo].lockIn;
        require( now > time, "Your contract is almost up");
        _;
    }
}