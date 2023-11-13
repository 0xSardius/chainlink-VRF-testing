// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract AstrodiceBasic is ERC721, VRFConsumerBaseV2 {

    // Enums of the Sign, Planet, and House combinations VRF will be used with. 12 each.
    enum Sign { Aries, Taurus, Gemini, Cancer, Leo, Virgo, Libra, Scorpio, Sagittarius, Capricorn, Aquarius, Pisces }
    enum Planet { Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto, NorthNode, SouthNode }
    enum House { First, Second, Third, Fourth, Fifth, Sixth, Seventh, Eighth, Ninth, Tenth, Eleventh, Twelfth }


    // State variables
    uint64 s_subscriptionId;
    address s_owner;
    VRFCoordinatorV2Interface COORDINATOR;
    address vrfCoordinator = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
    bytes32 s_keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 callbackGasLimit = 40000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  3;

    // Structs
    struct Reading {
        Sign sign;
        Planet planet;
        House house;
    }

    mapping(uint256 => Reading) public readings;
    mapping(uint256 => address) private requestIdToSender;

    event ReadingRequested(uint256 indexed requestId, address indexed requestor);
    event ReadingFulfilled(uint256 indexed requestId, uint256 tokenId);

    constructor(uint64 subscriptionId) ERC721("AstroDice", "ASTRODICE") VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        // s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    function requestReading(address roller) public returns(uint256 requestId) {
        // require(s_results[roller] == 0, "Already rolled");
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        requestIdToSender[requestId] = msg.sender;
        emit ReadingRequested(requestId, msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {

        // transform the result to a number between 1 and 12 for planets, signs and houses
        uint256 planetValue = (randomWords[0] % 12) + 1;
        uint256 signValue = (randomWords[1] % 12) + 1;
        uint256 houseValue = (randomWords[2] % 12) + 1;

        Reading memory newReading = Reading(getSignName[signValue], getPlanetName[planetValue], getHouseName[houseValue]);

        // NFT Mint code goes here?

        // emit readingFulfilled(requestId, d20Value);
        return newReading;
    }

    // Example code 
    

    // function house(address player) public view returns (string memory) {
    //     require(s_results[player] != 0, "Dice not rolled");

    //     require(s_results[player] != ROLL_IN_PROGRESS, "Dice roll in progress");

    //     return getHouseName(s_results[player]);
    // }

    // function planet(address player) public view returns (string memory) {
    //     // Not sure if the below is needed, but it's in the example code
    //     //require(s_results[player] != ROLL_IN_PROGRESS, "Dice roll in progress");

    //     return getPlanetName(s_results[player]);
    // }

    // Getter functions

    function getPlanetName(uint256 id) private pure returns (string memory) {
        // array storing the list of planet names
        string[12] memory planetNames = [
            "Sun",
            "Moon",
            "Mercury",
            "Venus",
            "Mars",
            "Jupiter",
            "Saturn",
            "Uranus",
            "Neptune",
            "Pluto",
            "North Node",
            "South Node"
        ];

        // returns the house name given an index
        return planetNames[id - 1];
    }

    function getSignName(uint256 id) private pure returns (string memory) {
        // array storing the list of planet names
        string[12] memory signNames = [
            "Aries",
            "Taurus",
            "Gemini",
            "Cancer",
            "Leo",
            "Virgo",
            "Libra",
            "Scorpio",
            "Sagittarius",
            "Capricorn",
            "Aquarius",
            "Pisces"
        ];

        // returns the house name given an index
        return signNames[id - 1];
    }

    function getHouseName(uint256 id) private pure returns (string memory) {
        // array storing the list of planet names
        string[12] memory houseNames = [
            "First House",
            "Second House",
            "Third House",
            "Fourth House",
            "Fifth House",
            "Sixth House",
            "Seventh House",
            "Eighth House",
            "Ninth House",
            "Tenth House",
            "Eleventh House",
            "Twelfth House"
        ];

        // returns the house name given an index
        return houseNames[id - 1];
    }





    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }
}