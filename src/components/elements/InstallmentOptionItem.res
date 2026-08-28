open ReactNative
open Style

@react.component
let make = (
  ~plan: ClientResponseType.installmentPlan,
  ~currency: string,
  ~isSelected: bool,
  ~onSelect: unit => unit,
) => {
  let {primaryColor, component, borderRadius, borderWidth} = ThemebasedStyle.useThemeBasedStyle()

  // Backend sends installment amounts in display units already, so they are shown
  // as is - only padded/truncated to two decimals.
  let amountPerInstallment =
    plan.amount_details.amount_per_installment->Utils.formatAmountWithTwoDecimals
  let totalAmount = plan.amount_details.total_amount->Utils.formatAmountWithTwoDecimals
  let interestLabel =
    plan.interest_rate == 0.
      ? InstallmentStrings.interestFree
      : InstallmentStrings.interestRate(plan.interest_rate->Utils.formatAmountWithTwoDecimals)

  <CustomPressable
    onPress={_ => onSelect()}
    style={s({
      flexDirection: #row,
      alignItems: #center,
      justifyContent: #"space-between",
      gap: 8.->dp,
      paddingVertical: 10.->dp,
      paddingHorizontal: 10.->dp,
      borderRadius,
      borderWidth,
      borderColor: isSelected ? primaryColor : component.borderColor,
    })}>
    <View style={s({flexDirection: #row, alignItems: #center, flexShrink: 1.})}>
      <CustomRadioButton size=18. selected=isSelected color=primaryColor />
      <Space width=8. />
      <View style={s({flexShrink: 1.})}>
        <TextWrapper
          text={InstallmentStrings.paymentLabel(
            ~count=plan.number_of_installments,
            ~currency,
            ~amount=amountPerInstallment,
          )}
          textType={CardTextBold}
        />
        <TextWrapper text=interestLabel textType={ModalTextLight} />
      </View>
    </View>
    <View style={s({alignItems: #"flex-end"})}>
      <TextWrapper text=InstallmentStrings.totalPayable textType={ModalTextLight} />
      <TextWrapper text={`${currency} ${totalAmount}`} textType={CardTextBold} />
    </View>
  </CustomPressable>
}
