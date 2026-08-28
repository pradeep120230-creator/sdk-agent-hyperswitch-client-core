open Utils

type layoutType = Tab | Accordion
type paymentMethodsArrangement = ArrangementDefault | ArrangementGrid
type cardBrandIcon =
  | CardBrandIconStandard
  | CardBrandIconHidden
  | CardBrandIconAnimated
  | CardBrandIconHideDefault
type groupingBehavior = {
  displayInSeparateScreen: bool,
  groupByPaymentMethods: bool,
}

type savedMethodCustomization = {
  groupingBehavior: groupingBehavior,
}

type layout = {
  layoutType: layoutType,
  showOneClickWalletsOnTop: bool,
  paymentMethodsArrangementForTabs: paymentMethodsArrangement,
  defaultCollapsed: bool,
  radios: bool,
  spacedAccordionItems: bool,
  maxAccordionItems: int,
  savedMethodCustomization: savedMethodCustomization,
  cardBrandIcon: cardBrandIcon,
}

let getCardBrandIconStyle = (str): cardBrandIcon =>
  switch str {
  | "hidden" => CardBrandIconHidden
  | "animated" => CardBrandIconAnimated
  | "hideDefault" => CardBrandIconHideDefault
  | "" | "standard" => CardBrandIconStandard
  | str =>
    Console.warn(
      `Unknown Value: '${str}' is an unknown/invalid value for appearance.layout.cardBrandIcon, please provide one of ["standard", "hidden", "animated", "hideDefault"]. This might cause issue in the future`,
    )
    CardBrandIconStandard
  }

/* Decides whether the card brand icon should be rendered at all.
   Kept pure and outside the components so both render sites share one rule. */
let getCardBrandIconVisibility = (setting: cardBrandIcon, ~cardBrand: string) =>
  switch setting {
  // Animated is reserved for future use; behaves like Standard for now
  | CardBrandIconStandard | CardBrandIconAnimated => true
  | CardBrandIconHidden => false
  | CardBrandIconHideDefault => cardBrand !== ""
  }

let defaultLayout: layout = {
  layoutType: Tab,
  showOneClickWalletsOnTop: true,
  paymentMethodsArrangementForTabs: ArrangementDefault,
  defaultCollapsed: false,
  radios: false,
  spacedAccordionItems: false,
  maxAccordionItems: 4,
  savedMethodCustomization: {
    groupingBehavior: {displayInSeparateScreen: true, groupByPaymentMethods: false},
  },
  cardBrandIcon: CardBrandIconStandard,
}

let parseLayout = (appearanceDict: Dict.t<JSON.t>) => {
  let layoutRaw = appearanceDict->Dict.get("layout")
  let layoutObj = layoutRaw->Option.flatMap(JSON.Decode.object)

  switch layoutObj {
  | Some(obj) => {
      let savedMethodCustomizationDict =
        obj->Dict.get("savedMethodCustomization")->Option.flatMap(JSON.Decode.object)
      {
        layoutType: switch getString(obj, "type", "tabs") {
        | "tabs" => Tab
        | "accordion" | "spacedAccordion" => Accordion
        | _ => Tab
        },
        showOneClickWalletsOnTop: getBool(obj, "showOneClickWalletsOnTop", true),
        paymentMethodsArrangementForTabs: switch getString(
          obj,
          "paymentMethodsArrangementForTabs",
          "default",
        ) {
        | "grid" => ArrangementGrid
        | _ => ArrangementDefault
        },
        defaultCollapsed: getBool(obj, "defaultCollapsed", false),
        radios: getBool(obj, "radios", false),
        spacedAccordionItems: getBool(obj, "spacedAccordionItems", false),
        maxAccordionItems: getInt(obj, "maxAccordionItems", 4),
        savedMethodCustomization: {
          groupingBehavior: switch savedMethodCustomizationDict {
          | Some(smDict) =>
            switch smDict->Dict.get("groupingBehavior")->Option.flatMap(JSON.Decode.object) {
            | Some(gbObj) => {
                displayInSeparateScreen: getBool(gbObj, "displayInSeparateScreen", true),
                groupByPaymentMethods: getBool(gbObj, "groupByPaymentMethods", false),
              }
            | None =>
              switch getString(smDict, "groupingBehavior", "default") {
              | "groupByPaymentMethods" => {
                  displayInSeparateScreen: false,
                  groupByPaymentMethods: true,
                }
              | _ => {displayInSeparateScreen: true, groupByPaymentMethods: false}
              }
            }
          | None => {displayInSeparateScreen: true, groupByPaymentMethods: false}
          },
        },
        cardBrandIcon: getString(obj, "cardBrandIcon", "standard")->getCardBrandIconStyle,
      }
    }
  | None =>
    {
      layoutType: switch getString(appearanceDict, "layout", "") {
      | "tabs" => Tab
      | "accordion" | "spacedAccordion" => Accordion
      | _ => Tab
      },
      showOneClickWalletsOnTop: true,
      paymentMethodsArrangementForTabs: ArrangementDefault,
      defaultCollapsed: false,
      radios: false,
      spacedAccordionItems: false,
      maxAccordionItems: 4,
      savedMethodCustomization: {
        groupingBehavior: {displayInSeparateScreen: true, groupByPaymentMethods: false},
      },
      cardBrandIcon: CardBrandIconStandard,
    }
  }
}
