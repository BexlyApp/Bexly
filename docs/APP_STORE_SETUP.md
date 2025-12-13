# App Store Setup Guide

This document contains all the configuration details for App Store Connect and Google Play Console.

## Subscription Setup

### Subscription Group
- **Group Name:** `Bexly Premium`
- **Grace Period:** 16 days (Production and Sandbox)

### Product IDs

| Plan | Product ID | Price (USD) | Price (VND) |
|------|------------|-------------|-------------|
| Plus Monthly | `bexly_plus_monthly` | $2.99/month | 79,000đ/tháng |
| Plus Yearly | `bexly_plus_yearly` | $29.99/year | 790,000đ/năm |
| Pro Monthly | `bexly_pro_monthly` | $5.99/month | 149,000đ/tháng |
| Pro Yearly | `bexly_pro_yearly` | $59.99/year | 1,490,000đ/năm |

### Subscription Features by Tier

See [PREMIUM_PLAN.md](./PREMIUM_PLAN.md) for full feature comparison.

---

## App Privacy (Data Collection)

Based on SDKs used in the app:
- Firebase Analytics
- Firebase Auth
- Firebase Crashlytics
- Cloud Firestore
- Google Mobile Ads (AdMob)

### Data Types Collected

#### Contact Info
- [x] **Email Address** - Firebase Auth (email login)

#### Financial Info
- [x] **Other Financial Info** - User transactions, income, expenses, budgets

#### Identifiers
- [x] **User ID** - Firebase Auth user ID
- [x] **Device ID** - AdMob, Firebase Analytics
- [x] **Purchases** - In-app subscription tracking

#### Usage Data
- [x] **Product Interaction** - Firebase Analytics (screen views, button taps, feature usage)
- [x] **Advertising Data** - AdMob (ads shown, ad interactions)

#### Diagnostics
- [x] **Crash Data** - Firebase Crashlytics
- [x] **Performance Data** - Firebase Analytics (app launch time, etc.)

### Data Usage Purposes

For each data type, indicate the purposes:

| Data Type | Analytics | Advertising | App Functionality | Linked to User |
|-----------|-----------|-------------|-------------------|----------------|
| Email Address | No | No | Yes | Yes |
| Other Financial Info | No | No | Yes | Yes |
| User ID | Yes | No | Yes | Yes |
| Device ID | Yes | Yes | No | No |
| Purchases | Yes | No | Yes | Yes |
| Product Interaction | Yes | No | No | No |
| Advertising Data | No | Yes | No | No |
| Crash Data | Yes | No | No | No |
| Performance Data | Yes | No | No | No |

### Data NOT Collected
- Name
- Phone Number
- Physical Address
- Health & Fitness data
- Location (Precise or Coarse)
- Photos or Videos
- Contacts
- Browsing History
- Search History

---

## Store Listings

See [store_listings.csv](../store_listings.csv) for all localized store listing content.

### Supported Languages (11)
- English (US) - en-US
- Vietnamese - vi
- German - de
- Spanish - es
- Portuguese (Brazil) - pt-BR
- Russian - ru
- Dutch - nl
- Indonesian - id
- French - fr
- Italian - it
- Polish - pl

### Character Limits

| Field | iOS Limit | Google Play Limit |
|-------|-----------|-------------------|
| App Name | 30 chars | 50 chars |
| Subtitle (iOS only) | 30 chars | N/A |
| Short Description | N/A | 80 chars |
| Promotional Text | 170 chars | N/A |
| Full Description | 4000 chars | 4000 chars |

---

## App Store Screenshots

### Required Sizes

**iPhone:**
- 6.7" (1290 x 2796) - iPhone 15 Pro Max, 14 Pro Max
- 6.5" (1284 x 2778) - iPhone 14 Plus, 13 Pro Max
- 5.5" (1242 x 2208) - iPhone 8 Plus

**iPad:**
- 12.9" (2048 x 2732) - iPad Pro 12.9"

### Screenshot Content Suggestions
1. Dashboard with spending overview
2. Transaction entry with AI categorization
3. Budget tracking progress
4. AI chat conversation
5. Multi-wallet management
6. Analytics/Reports charts

---

## App Review Information

### Contact Information
- Email: help@bexly.app

### Demo Account (if required)
- Provide test account credentials for review
- Or note: "No login required for basic features"

### Notes for Reviewer
```
Bexly is a personal finance app that helps users track expenses and manage budgets.

Key features to test:
1. Add a transaction (tap + button)
2. View spending analytics
3. Chat with AI about finances
4. Create budgets and goals

The app works offline and doesn't require login for basic features.
Cloud sync and premium features require sign-in.
```

---

## Common Rejection Reasons & Solutions

### 1. Guideline 2.1 - App Completeness
- Ensure all features work
- Remove placeholder content
- Test all in-app purchases

### 2. Guideline 3.1.1 - In-App Purchase
- All premium features must use Apple IAP
- Cannot link to external payment methods
- Restore purchases must work

### 3. Guideline 5.1.1 - Data Collection
- Privacy policy URL required
- App Privacy labels must be accurate
- Request only necessary permissions

### 4. Metadata Rejected
- Screenshots must reflect actual app
- No pricing in screenshots (varies by region)
- App name cannot include price or ranking

---

## Checklist Before Submission

### iOS (App Store Connect)
- [ ] App icon uploaded (1024x1024)
- [ ] Screenshots for all required device sizes
- [ ] App Privacy questionnaire completed
- [ ] Subscription products created and approved
- [ ] Privacy Policy URL added
- [ ] Support URL added
- [ ] Age rating questionnaire completed
- [ ] Build uploaded and processed

### Android (Google Play Console)
- [ ] Feature graphic (1024x500)
- [ ] Screenshots uploaded
- [ ] Data safety form completed
- [ ] Subscription products created
- [ ] Privacy Policy URL added
- [ ] Content rating questionnaire completed
- [ ] App bundle uploaded

---

## Useful Links

- App Store Connect: https://appstoreconnect.apple.com
- Google Play Console: https://play.google.com/console
- Firebase Console: https://console.firebase.google.com
- App Privacy Generator: https://app-privacy-policy-generator.nisrulz.com
