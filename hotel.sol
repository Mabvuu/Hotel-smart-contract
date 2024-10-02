pragma solidity ^0.5.16;

contract Hostel {
    // Removed unused global tenant and landlord variables
    // address payable tenant;
    // address payable landlord;

    uint public no_of_rooms = 0;
    uint public no_of_agreement = 0;
    uint public no_of_rent = 0;

    struct Room {
        uint roomid;
        uint agreementid;
        string roomname;
        string roomaddress;
        uint rent_per_month;
        uint securityDeposit;
        uint timestamp;
        bool vacant;
        address payable landlord;
        address payable currentTenant;
    }

    mapping(uint => Room) public Room_by_No;

    struct RoomAgreement {
        uint roomid;
        uint agreementid;
        string roomname;
        string roomaddress;
        uint rent_per_month;
        uint securityDeposit;
        uint timestamp;
        bool vacant;
        address payable landlord;
        address payable currentTenant;
        uint lockIn; // Added lockIn to track agreement duration
    }

    mapping(uint => RoomAgreement) public RoomAgreement_by_No;

    struct Rent {
        uint rentId;
        uint roomid;
        uint agreementid;
        string roomname;
        string roomaddress;
        uint rent_per_month;
        uint securityDeposit;
        uint timestamp;
        bool vacant;
        address payable landlord;
        address payable currentTenant;
    }

    mapping(uint => Rent) public Rent_by_No;

    // Modifiers

    // Ensures only the landlord can call the function
    modifier onlyLandLord(uint _index) {
        require(msg.sender == Room_by_No[_index].landlord, "Only landlord can access this");
        _;
    }

    // Ensures only tenants (not landlords) can call the function
    modifier notLandLord(uint _index) {
        require(msg.sender != Room_by_No[_index].landlord, "Only Tenant can access this");
        _;
    }

    // Ensures the room is vacant
    modifier OnlyWhileVacant(uint _index) {
        require(Room_by_No[_index].vacant == true, "Room is currently Occupied");
        _;
    }

    // Ensures the tenant has sent enough Ether for rent
    modifier enoughRent(uint _index) {
        require(msg.value >= Room_by_No[_index].rent_per_month, "Not enough Ether for rent");
        _;
    }

    // Ensures the tenant has sent enough Ether for rent and security deposit
    modifier enoughAgreementfee(uint _index) {
        uint totalFee = Room_by_No[_index].rent_per_month + Room_by_No[_index].securityDeposit;
        require(msg.value >= totalFee, "Insufficient funds for rent and deposit");
        _;
    }

    // Ensures the caller is the current tenant
    modifier sameTenant(uint _index) {
        require(msg.sender == Room_by_No[_index].currentTenant, "No agreement found with this tenant");
        _;
    }

    // Ensures the agreement is still active
    modifier AgreementTimesLeft(uint _index) {
        uint _AgreementNo = Room_by_No[_index].agreementid;
        uint time = RoomAgreement_by_No[_AgreementNo].timestamp + RoomAgreement_by_No[_AgreementNo].lockIn;
        require(now < time, "Agreement has already ended");
        _;
    }

    // Ensures the agreement period has ended
    modifier AgreementTimesUp(uint _index) {
        uint _AgreementNo = Room_by_No[_index].agreementid;
        uint time = RoomAgreement_by_No[_AgreementNo].timestamp + RoomAgreement_by_No[_AgreementNo].lockIn;
        require(now > time, "Agreement period is not yet over");
        _;
    }

    // Ensures it's time to pay rent
    modifier RentTimesUp(uint _index) {
        uint time = Room_by_No[_index].timestamp + 30 days;
        require(now >= time, "Time left to pay rent");
        _;
    }

    // Functions

    /**
     * @dev Adds a new room to the contract.
     * @param _roomname Name of the room.
     * @param _roomaddress Address of the room.
     * @param _rentcost Monthly rent cost.
     * @param _securitydeposit Security deposit amount.
     */
    function addRoom(
        string memory _roomname,
        string memory _roomaddress,
        uint _rentcost,
        uint _securitydeposit
    ) public {
        require(msg.sender != address(0), "Invalid sender");

        no_of_rooms++;

        Room_by_No[no_of_rooms] = Room(
            no_of_rooms,
            0,
            _roomname,
            _roomaddress,
            _rentcost,
            _securitydeposit,
            now, // Using block timestamp
            true, // Room is initially vacant
            msg.sender, // Landlord is the sender
            address(0) // No current tenant
        );
    }

    /**
     * @dev Allows a tenant to sign an agreement for a room.
     * @param _index Room ID.
     */
    function signAgreement(uint _index)
        public
        payable
        notLandLord(_index)
        enoughAgreementfee(_index)
        OnlyWhileVacant(_index)
    {
        require(msg.sender != address(0), "Invalid sender");

        Room storage room = Room_by_No[_index];
        address payable _landlord = room.landlord;
        uint totalFee = room.rent_per_month + room.securityDeposit;

        // Transfer only the rent to the landlord
        _landlord.transfer(room.rent_per_month);
        // The security deposit remains in the contract

        no_of_agreement++;

        // Update room details
        room.currentTenant = msg.sender;
        room.vacant = false;
        room.timestamp = now;
        room.agreementid = no_of_agreement;

        // Create a new RoomAgreement
        RoomAgreement_by_No[no_of_agreement] = RoomAgreement(
            _index,
            no_of_agreement,
            room.roomname,
            room.roomaddress,
            room.rent_per_month,
            room.securityDeposit,
            now,
            false, // Agreement is active
            _landlord,
            msg.sender,
            365 days // Example lock-in period; adjust as needed
        );

        // Record the rent payment
        no_of_rent++;
        Rent_by_No[no_of_rent] = Rent(
            no_of_rent,
            _index,
            no_of_agreement,
            room.roomname,
            room.roomaddress,
            room.rent_per_month,
            room.securityDeposit,
            now,
            false,
            _landlord,
            msg.sender
        );
    }

    /**
     * @dev Allows the tenant to pay rent.
     * @param _index Room ID.
     */
    function payRent(uint _index)
        public
        payable
        sameTenant(_index)
        RentTimesUp(_index)
        enoughRent(_index)
    {
        require(msg.sender != address(0), "Invalid sender");

        Room storage room = Room_by_No[_index];
        address payable _landlord = room.landlord;
        uint _rent = room.rent_per_month;

        // Transfer rent to the landlord
        _landlord.transfer(_rent);

        // Update room timestamp for the next rent cycle
        room.timestamp = now;

        // Record the rent payment
        no_of_rent++;
        Rent_by_No[no_of_rent] = Rent(
            no_of_rent,
            _index,
            room.agreementid,
            room.roomname,
            room.roomaddress,
            _rent,
            room.securityDeposit,
            now,
            false,
            _landlord,
            room.currentTenant
        );
    }

    /**
     * @dev Completes the agreement and returns the security deposit to the tenant.
     * @param _index Room ID.
     */
    function agreementCompleted(uint _index)
        public
        onlyLandLord(_index)
        AgreementTimesUp(_index)
    {
        require(msg.sender != address(0), "Invalid sender");
        Room storage room = Room_by_No[_index];
        require(room.vacant == false, "Room is already vacant");

        // Mark the room as vacant
        room.vacant = true;

        address payable _tenant = room.currentTenant;
        uint _securityDeposit = room.securityDeposit;

        // Transfer the security deposit back to the tenant
        _tenant.transfer(_securityDeposit);

        // Reset tenant information
        room.currentTenant = address(0);
        room.agreementid = 0;
    }

   
    function agreementTerminated(uint _index)
        public
        onlyLandLord(_index)
        AgreementTimesLeft(_index)
    {
        require(msg.sender != address(0), "Invalid sender");

        Room storage room = Room_by_No[_index];
        room.vacant = true;

       
        room.currentTenant = address(0);
        room.agreementid = 0;
    }
}
