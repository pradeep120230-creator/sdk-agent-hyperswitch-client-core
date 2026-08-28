// English copy for the installment (EMI) block.
//
// The shared locale contract (LocaleDataType.localeStrings) lives in the
// shared-code submodule and holds plain strings only, so the two parameterised
// labels are formatted here instead of being stored as record fields.
let payInInstallments = "Pay in installments"

let choosePlan = "Choose an installment plan"

let interestFree = "Interest free"

let interestRate = rate => `${rate}% interest`

let totalPayable = "Total payable"

let paymentLabel = (~count: int, ~currency: string, ~amount: string) =>
  count === 1
    ? `1 payment of ${currency} ${amount}`
    : `${count->Int.toString} payments of ${currency} ${amount}`

let selectPlanError = "Please select an installment plan"
