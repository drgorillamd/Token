declare const contracts: {
    factory: {
        address: string;
        abi: ({
            anonymous: boolean;
            inputs: {
                indexed: boolean;
                internalType: string;
                name: string;
                type: string;
            }[];
            name: string;
            type: string;
            constant?: undefined;
            outputs?: undefined;
            payable?: undefined;
            stateMutability?: undefined;
        } | {
            constant: boolean;
            inputs: {
                internalType: string;
                name: string;
                type: string;
            }[];
            name: string;
            outputs: {
                internalType: string;
                name: string;
                type: string;
            }[];
            payable: boolean;
            stateMutability: string;
            type: string;
            anonymous?: undefined;
        })[];
    };
    pair: {
        abi: ({
            anonymous: boolean;
            inputs: {
                indexed: boolean;
                internalType: string;
                name: string;
                type: string;
            }[];
            name: string;
            type: string;
            constant?: undefined;
            outputs?: undefined;
            payable?: undefined;
            stateMutability?: undefined;
        } | {
            constant: boolean;
            inputs: {
                internalType: string;
                name: string;
                type: string;
            }[];
            name: string;
            outputs: {
                internalType: string;
                name: string;
                type: string;
            }[];
            payable: boolean;
            stateMutability: string;
            type: string;
            anonymous?: undefined;
        })[];
    };
    router01: {
        address: string;
        abi: {
            inputs: {
                internalType: string;
                name: string;
                type: string;
            }[];
            name: string;
            outputs: {
                internalType: string;
                name: string;
                type: string;
            }[];
            stateMutability: string;
            type: string;
        }[];
    };
    router02: {
        address: string;
        abi: {
            inputs: {
                internalType: string;
                name: string;
                type: string;
            }[];
            name: string;
            outputs: {
                internalType: string;
                name: string;
                type: string;
            }[];
            stateMutability: string;
            type: string;
        }[];
    };
};
export default contracts;
