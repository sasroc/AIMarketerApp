import SwiftUI

struct PrivacyView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Privacy Policy")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Last Updated: \(Date().formatted(date: .abbreviated, time: .omitted))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Content sections
                        VStack(alignment: .leading, spacing: 20) {
                            PrivacySection(
                                title: "1. Information We Collect",
                                content: """
                                We collect information that you provide directly to us, including:
                                
                                • Account Information: Name, email address, and profile information
                                • Content Data: Marketing plans, posts, captions, and media you create
                                • Usage Data: How you interact with our services
                                • Device Information: Device type, operating system, and unique identifiers
                                """
                            )
                            
                            PrivacySection(
                                title: "2. How We Use Your Information",
                                content: """
                                We use the information we collect to:
                                
                                • Provide, maintain, and improve our services
                                • Process and deliver your scheduled posts
                                • Send you technical notices and support messages
                                • Respond to your comments and questions
                                • Monitor and analyze usage patterns
                                """
                            )
                            
                            PrivacySection(
                                title: "3. Information Sharing",
                                content: """
                                We do not sell your personal information. We may share your information only:
                                
                                • With your Instagram account (to post content as you direct)
                                • With service providers who assist us in operating our services
                                • When required by law or to protect our rights
                                • With your consent
                                """
                            )
                            
                            PrivacySection(
                                title: "4. Data Security",
                                content: """
                                We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.
                                
                                However, no method of transmission over the internet is 100% secure. While we strive to protect your data, we cannot guarantee absolute security.
                                """
                            )
                            
                            PrivacySection(
                                title: "5. Your Rights",
                                content: """
                                You have the right to:
                                
                                • Access your personal information
                                • Correct inaccurate data
                                • Delete your account and data
                                • Export your data
                                • Opt out of certain communications
                                
                                To exercise these rights, contact us through the Help & Support section.
                                """
                            )
                            
                            PrivacySection(
                                title: "6. Data Retention",
                                content: """
                                We retain your information for as long as your account is active or as needed to provide services. If you delete your account, we will delete or anonymize your information within 30 days, except where we are required to retain it for legal purposes.
                                """
                            )
                            
                            PrivacySection(
                                title: "7. Children's Privacy",
                                content: """
                                Our services are not intended for users under the age of 13. We do not knowingly collect personal information from children under 13. If we become aware that we have collected such information, we will take steps to delete it.
                                """
                            )
                            
                            PrivacySection(
                                title: "8. Changes to This Policy",
                                content: """
                                We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last Updated" date. You are advised to review this policy periodically.
                                """
                            )
                            
                            PrivacySection(
                                title: "9. Contact Us",
                                content: """
                                If you have any questions about this Privacy Policy, please contact us through the Help & Support section in the app.
                                """
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PrivacySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(content)
                .font(.body)
                .foregroundColor(.gray)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.marketingCardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    PrivacyView()
}

