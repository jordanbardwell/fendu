import Foundation

struct CardIssuer: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let cards: [String]
}

struct CreditCardCatalog {
    static let issuers: [CardIssuer] = [
        CardIssuer(name: "American Express", cards: [
            "Platinum Card",
            "Gold Card",
            "Green Card",
            "Blue Cash Preferred",
            "Blue Cash Everyday",
            "Delta SkyMiles Gold",
            "Delta SkyMiles Platinum",
            "Delta SkyMiles Reserve",
            "Hilton Honors",
            "Hilton Honors Surpass",
            "Hilton Honors Aspire",
            "Marriott Bonvoy",
            "Marriott Bonvoy Brilliant",
            "Business Platinum",
            "Business Gold",
            "Blue Business Plus",
            "Blue Business Cash"
        ]),
        CardIssuer(name: "Apple", cards: [
            "Apple Card"
        ]),
        CardIssuer(name: "Bank of America", cards: [
            "Customized Cash Rewards",
            "Unlimited Cash Rewards",
            "Travel Rewards",
            "Premium Rewards",
            "Premium Rewards Elite",
            "Alaska Airlines Visa"
        ]),
        CardIssuer(name: "Barclays", cards: [
            "AAdvantage Aviator Red",
            "AAdvantage Aviator Silver",
            "JetBlue Card",
            "JetBlue Plus Card",
            "Wyndham Rewards Earner",
            "Wyndham Rewards Earner Plus"
        ]),
        CardIssuer(name: "Capital One", cards: [
            "Venture X",
            "Venture",
            "VentureOne",
            "Savor",
            "SavorOne",
            "Quicksilver",
            "Platinum"
        ]),
        CardIssuer(name: "Chase", cards: [
            "Sapphire Reserve",
            "Sapphire Preferred",
            "Freedom Unlimited",
            "Freedom Flex",
            "Freedom Rise",
            "Slate Edge",
            "Southwest Rapid Rewards Priority",
            "Southwest Rapid Rewards Plus",
            "Southwest Rapid Rewards Premier",
            "United Explorer",
            "United Quest",
            "United Club Infinite",
            "IHG One Rewards Premier",
            "Marriott Bonvoy Boundless",
            "Marriott Bonvoy Bold",
            "Ink Business Preferred",
            "Ink Business Unlimited",
            "Ink Business Cash",
            "Amazon Prime Visa"
        ]),
        CardIssuer(name: "Citi", cards: [
            "Double Cash",
            "Custom Cash",
            "Strata Premier",
            "Rewards+",
            "Simplicity",
            "Diamond Preferred",
            "AAdvantage Platinum Select",
            "AAdvantage Executive",
            "Costco Anywhere Visa"
        ]),
        CardIssuer(name: "Discover", cards: [
            "it Cash Back",
            "it Miles",
            "it Chrome",
            "it Student Cash Back",
            "it Student Chrome"
        ]),
        CardIssuer(name: "Navy Federal", cards: [
            "Visa Signature Flagship Rewards",
            "More Rewards Visa Signature",
            "cashRewards",
            "Go Rewards",
            "Platinum"
        ]),
        CardIssuer(name: "Robinhood", cards: [
            "Gold Card"
        ]),
        CardIssuer(name: "US Bank", cards: [
            "Altitude Reserve",
            "Altitude Go",
            "Altitude Connect",
            "Cash+",
            "Platinum",
            "Shopper Cash Rewards"
        ]),
        CardIssuer(name: "Wells Fargo", cards: [
            "Active Cash",
            "Autograph",
            "Autograph Journey",
            "Reflect",
            "Platinum"
        ])
    ]
}
