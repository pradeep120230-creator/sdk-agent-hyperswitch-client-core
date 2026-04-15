open ReactNative
open Style

module PlanItem = {
  @react.component
  let make = (
    ~plan: AccountPaymentMethodType.installmentPlan,
    ~currency: string,
    ~isSelected: bool,
    ~onSelect: unit => unit,
  ) => {
    let {primaryColor, component} = ThemebasedStyle.useThemeBasedStyle()
    let localeObject = GetLocale.useGetLocalObj()
    let amountPerInstallment = plan.amount_details.amount_per_installment
    let totalAmount = plan.amount_details.total_amount
    let isInterestFree = plan.interest_rate <= 0.0

    <CustomPressable onPress={_ => onSelect()} style={s({
      flexDirection: #row,
      alignItems: #center,
      paddingVertical: 10.->dp,
      paddingHorizontal: 12.->dp,
      borderBottomWidth: 0.5,
      borderBottomColor: component.borderColor,
    })}>
      <CustomRadioButton size=18. selected=isSelected color=primaryColor />
      <Space width=10. />
      <View style={s({flex: 1.})}>
        <View style={s({flexDirection: #row, alignItems: #center, justifyContent: #"space-between"})}>
          <TextWrapper
            text={`${plan.number_of_installments->Int.toString} x ${currency} ${amountPerInstallment->Float.toFixed(~digits=2)}`}
            textType={CardTextBold}
          />
          <TextWrapper
            text={isInterestFree ? localeObject.installmentInterestFree : localeObject.installmentWithInterest}
            textType={ModalTextLight}
          />
        </View>
        <TextWrapper
          text={`${localeObject.installmentTotal}: ${currency} ${totalAmount->Float.toFixed(~digits=2)}`}
          textType={ModalTextLight}
        />
      </View>
    </CustomPressable>
  }
}

@react.component
let make = (
  ~installmentPlans: array<AccountPaymentMethodType.installmentPlan>,
  ~currency: string,
  ~selectedPlan: option<AccountPaymentMethodType.installmentPlan>,
  ~setSelectedPlan: (
    option<AccountPaymentMethodType.installmentPlan> => option<AccountPaymentMethodType.installmentPlan>
  ) => unit,
  ~showInstallments: bool,
  ~setShowInstallments: (bool => bool) => unit,
  ~errorText: option<string>,
) => {
  let localeObject = GetLocale.useGetLocalObj()
  let {component, borderRadius} = ThemebasedStyle.useThemeBasedStyle()

  if installmentPlans->Array.length === 0 {
    React.null
  } else {
    <View style={s({marginTop: 12.->dp})}>
      <ClickableTextElement
        initialIconName="checkboxClicked"
        updateIconName=Some("checkboxNotClicked")
        text={localeObject.installmentPayInInstallments}
        isSelected={showInstallments}
        setIsSelected={selected => setShowInstallments(_ => selected)}
        textType={TextWrapper.ModalText}
      />
      {showInstallments
        ? <View style={s({
            marginTop: 8.->dp,
            borderWidth: 1.,
            borderColor: component.borderColor,
            borderRadius,
            backgroundColor: component.background,
            maxHeight: 200.->dp,
            overflow: #hidden,
          })}>
            <ScrollView keyboardShouldPersistTaps=#handled showsVerticalScrollIndicator=true>
              {installmentPlans
              ->Array.mapWithIndex((plan, i) => {
                let isSelected = switch selectedPlan {
                | Some(selected) =>
                  selected.number_of_installments === plan.number_of_installments &&
                  selected.billing_frequency === plan.billing_frequency
                | None => false
                }
                <PlanItem
                  key={Int.toString(i)}
                  plan
                  currency
                  isSelected
                  onSelect={() => setSelectedPlan(_ => Some(plan))}
                />
              })
              ->React.array}
            </ScrollView>
          </View>
        : React.null}
      {errorText->Option.isSome
        ? <View style={s({marginTop: 4.->dp})}>
            <ErrorText text=errorText />
          </View>
        : React.null}
    </View>
  }
}
