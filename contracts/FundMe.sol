// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";
import "hardhat/console.sol";

error FundMe__NotOwner(); // конвенция для именования ошибок "ИмяКонтракта__Ошибка"
error FundMe__NotEnoughSent();
error FundMe__CallFailed();

//error появились с версии 0.8.4

/** 
    @title A contract for crowd funding
    @author Andrey
    @notice This contract is sample demo
    @dev This implements price feeds as our library
*/
// выше пример NatSpec формата для комментариев, помогает делать документацию для контрактов

contract FundMe {
    /** 
        конвенция очередности записи внутри контракта:
        Type declarations
        State variables
        Events
        Modifiers
        Functions
     */

    using PriceConverter for uint256; // позволяет привязывать методы библиотеки к типу данных ( uint256.ourMethod() ), при этом первым параметром будет само число

    uint256 public constant MINIMUM_USD = 0.5 * 1e18; // 0.5$, число с 18 нулями
    //constant экономит газ тк переменная не занимает память

    address[] private s_funders;

    mapping(address => uint256) private s_addressToAmountFunded;

    address private immutable i_owner;
    //immutable для переменных которые сетим один раз, экономит газ, название по конвенции начинается с "i_"

    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        // модификатор для функции
        // require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        // использование кастомных ошибок вместо require экономит газ, тк текстк ошибки в require это массив букв что требует память
        _; // нижнее подчеркивание обозначает выполнения остального кода функции
    }

    // modifier onlyOwner() { // модификатор для функции
    //     _;
    //     require(msg.sender == owner, "Sender is not owner");
    // } // здесь наоборот, сначала выполнения кода функции а затем модификатора

    /**
        Очередность функций по конвенции
        constructor
        recieve
        fallback
        external
        public
        internal
        private
        view/pure
     */

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // receive() external payable {
    //     fund();
    // }

    // fallback() external payable {
    //     fund();
    // }

    /**
        @notice This function funds this contract
    */

    function fund() public payable {
        // payable для отправки токенов
        if (msg.value.getConversionRate(s_priceFeed) <= MINIMUM_USD) {
            // getConversionRate первый параметр это всегда число с которым мы работаем, то что передаем вручную уже будет вторым параметром
            revert FundMe__NotEnoughSent();
        } // 1e18 = 1 * 10 ** 18 = 1000000000000000000 = 1 Eth
        //18 decimals (wei)

        // console.log("MINIMUM_USD", MINIMUM_USD);
        // console.log("VALUE", msg.value);
        // console.log("SENDER", msg.sender);
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        // применение нашего модификатора, модификаторы выполняются в первую очередь до выполнения функции
        for (
            uint256 funderIndex;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0); // reset array

        /*
            3 способа:

            transfer(2300 gas, throws error)
            send(2300 gas, returns bool)
            call(forward all gas or set gas, returns bool)
        */
        //transfer
        // payable(msg.sender).transfer(address(this).balance); // address(this) - текущий контракт, transfer при ошибке кинет ошибку и закончит функцию
        //         //payable() - typecasting, обертка над адресом
        // bool sendSuccess = payable(msg.sender).send(address(this).balance); // при ошибке вернет false, и код ниже выполнится
        // require(sendSuccess, "Send failed");
        // (bool callSuccess, bytes memory dataReturned) => payable(msg.sender).call{value: address(this).balance}(""); // так же возвращает данные в ответе
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(""); // call рекомендуемый способ
        if (!callSuccess) {
            revert FundMe__CallFailed();
        }
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // создаем новую memory переменную которая копирует переменную из хранилища
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        if (!success) {
            revert FundMe__CallFailed();
        }
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
