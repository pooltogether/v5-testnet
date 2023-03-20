export type Version = {
  major: number;
  minor: number;
  patch: number;
}

export type Contract = {
  chainId: number;
  address: string;
  version: Version;
  type: string;
  tokens?: VaultInfo[];
}

export type ContractList = {
  name: string;
  version: Version;
  contracts: Contract[]
}

export type VaultExtensionValue = string | number | boolean | null | undefined

export interface VaultExtensions {
  readonly yieldSource: string
  readonly underlyingAsset: {
    readonly chainId: number
    readonly address: `0x${string}`
    readonly symbol: string
    readonly name: string
    readonly decimals: number
    readonly logoURI?: string
  }
  readonly [key: string]:
  | {
    [key: string]:
    | {
      [key: string]: VaultExtensionValue
    }
    | VaultExtensionValue
  }
  | VaultExtensionValue
}

export interface VaultInfo {
  readonly chainId: number
  readonly address: `0x${string}`
  readonly name: string
  readonly decimals: number
  readonly symbol: string
  readonly extensions: VaultExtensions
  readonly tags?: string[]
  readonly logoURI?: string
}
