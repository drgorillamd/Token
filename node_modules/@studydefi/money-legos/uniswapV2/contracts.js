"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var IUniswapV2Factory_json_1 = __importDefault(require("./abi/IUniswapV2Factory.json"));
var IUniswapV2Pair_json_1 = __importDefault(require("./abi/IUniswapV2Pair.json"));
var IUniswapV2Router01_json_1 = __importDefault(require("./abi/IUniswapV2Router01.json"));
var IUniswapV2Router02_json_1 = __importDefault(require("./abi/IUniswapV2Router02.json"));
var contracts = {
    factory: {
        address: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
        abi: IUniswapV2Factory_json_1.default,
    },
    pair: {
        abi: IUniswapV2Pair_json_1.default,
    },
    router01: {
        address: "0xf164fC0Ec4E93095b804a4795bBe1e041497b92a",
        abi: IUniswapV2Router01_json_1.default,
    },
    router02: {
        address: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
        abi: IUniswapV2Router02_json_1.default,
    },
};
exports.default = contracts;
