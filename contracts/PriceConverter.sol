// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    //в библиотеках нельзя создавать глобальные переменные и слать токены
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        //address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e адрес контракта chailink eth/usd rinkeby для получение цены эфира

        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // ); // для доступа к контрактам в сети используем адрес контракта обернутый в его интерфейс
        (, int256 price, , , ) = priceFeed.latestRoundData(); // () = деструктуризация, функция latestRoundData возвращает несколько переменных
        //ETH to USD price
        return uint256(price * 1e10); //1 * 10 ** 10 = 10000000000, в функции fund мы работает с 18 decimal, price возвращает 8 decimals, поэтому степень 10-и, т.е из числа с 8 нулями сделать число с 18-ю
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUSD;
    }
}
