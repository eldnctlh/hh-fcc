const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { network } = require("hardhat")
const { verify } = require("../utils/verify")

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY

module.exports = async (hre) => {
    const { getNamedAccounts, deployments } = hre
    const { deploy, log, get } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    let ethUsdPriceFeedAddress

    if (developmentChains.includes(network.name)) {
        const ethUsdAggregator = await get("MockV3Aggregator")
        ethUsdPriceFeedAddress = ethUsdAggregator.address
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
    }

    const args = [ethUsdPriceFeedAddress]

    const fundMe = await deploy("FundMe", {
        from: deployer,
        args, // аргументы для конструктора,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1, // подождать определенное количество блоков, указанных в конфиге
    })

    if (!developmentChains.includes(network.name) && ETHERSCAN_API_KEY) {
        await verify(fundMe.address, args)
    }

    log("----------------Fund me deployed----------------")
}

module.exports.tags = ["all", "fundme"] //yarn hardhat deploy --tags fundme
