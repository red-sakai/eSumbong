import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hardcoded response map for Ezu — keyed by lowercase keywords found in the
/// user's message.  Entries are checked in order; first match wins.
///
/// NOTE: All responses use plain text only — no Markdown bold (**) markers.
/// The chat bubbles render with a plain Flutter Text widget, so Markdown
/// would appear as literal asterisks.
const List<(List<String>, String)> _ezuRules = <(List<String>, String)>[
  // ── Greetings ────────────────────────────────────────────────────────────
  (
    ['hello', 'hi', 'hey', 'kumusta', 'magandang'],
    'Hello! 👋 I am Ezu, your Philippine legal assistant inside eSumbong.\n\n'
        'I can help you with:\n'
        '• Katarungang Pambarangay process\n'
        '• Republic Acts (RA 9262, RA 7160, RA 7610, RA 9344, RA 10173)\n'
        '• Barangay dispute resolution\n\n'
        'What would you like to know?',
  ),

  // ── RA 9262 — VAWC ───────────────────────────────────────────────────────
  (
    ['9262', 'vawc', 'violence against women', 'domestic violence', 'abuso'],
    '📋 RA 9262 — Anti-Violence Against Women and Their Children Act of 2004\n\n'
        'Purpose:\n'
        'Protects women and their children from physical, sexual, psychological, '
        'and economic abuse by their intimate partners or family members.\n\n'
        'Key Provisions:\n'
        '• Covers acts of violence by a husband, former husband, or any person with whom the woman has/had a sexual or dating relationship\n'
        '• Victims may apply for a Barangay Protection Order (BPO), Temporary Protection Order (TPO), or Permanent Protection Order (PPO)\n'
        '• BPOs are issued by the barangay and are effective for 15 days\n'
        '• Psychological and economic abuse are recognized forms of violence\n\n'
        'Penalties:\n'
        'Imprisonment ranging from 1 month to 20 years, depending on the gravity of the offense, plus fines.\n\n'
        '⚠️ This is general legal information only and does not constitute legal advice. Consult a licensed Philippine attorney for case-specific guidance.',
  ),

  // ── RA 7160 — Local Government Code ──────────────────────────────────────
  (
    ['7160', 'local government code', 'lgc', 'katarungang pambarangay', 'lupon'],
    '📋 RA 7160 — Local Government Code of 1991\n\n'
        'Purpose:\n'
        'Decentralizes government functions and empowers local government units (LGUs), including barangays.\n\n'
        'Key Provisions (Barangay Justice):\n'
        '• Establishes the Katarungang Pambarangay system (Chapter 7, Title I, Book III)\n'
        '• Creates the Lupon Tagapamayapa — a body of 10–20 members tasked with settling disputes at the barangay level\n'
        '• Most civil disputes and minor criminal offenses must first go through barangay conciliation before courts can hear them\n'
        '• Disputes between residents of the same barangay are covered\n\n'
        'Penalties:\n'
        'Non-compliance with the mandatory conciliation requirement results in dismissal of the case in court.\n\n'
        '⚠️ This is general legal information only and does not constitute legal advice. Consult a licensed Philippine attorney for case-specific guidance.',
  ),

  // ── RA 7610 — Child Abuse ─────────────────────────────────────────────────
  (
    ['7610', 'child abuse', 'child exploitation', 'bata', 'minor'],
    '📋 RA 7610 — Special Protection of Children Against Abuse, Exploitation and Discrimination Act\n\n'
        'Purpose:\n'
        'Provides stronger deterrence against child abuse, exploitation, and discrimination, '
        'and grants special protection to children in difficult circumstances.\n\n'
        'Key Provisions:\n'
        '• Defines child abuse as maltreatment — physical, psychological, or emotional — of a child below 18 years old\n'
        '• Covers child prostitution, trafficking, obscene publications, and situations of armed conflict\n'
        '• Mandates the State to provide preventive measures, treatment, rehabilitation, and reintegration for abused children\n'
        '• Local government units are required to establish a local council for the protection of children\n\n'
        'Penalties:\n'
        'Imprisonment of 6 years and 1 day to 40 years, depending on the offense, plus perpetual or temporary disqualification from public office.\n\n'
        '⚠️ This is general legal information only and does not constitute legal advice. Consult a licensed Philippine attorney for case-specific guidance.',
  ),

  // ── RA 9344 — Juvenile Justice ────────────────────────────────────────────
  (
    ['9344', 'juvenile', 'child in conflict', 'cicl', 'youth offender'],
    '📋 RA 9344 — Juvenile Justice and Welfare Act of 2006\n\n'
        'Purpose:\n'
        'Establishes a comprehensive juvenile justice and welfare system to address the needs '
        'of children in conflict with the law (CICL).\n\n'
        'Key Provisions:\n'
        '• Minimum age of criminal responsibility: 15 years old (as amended by RA 10630)\n'
        '• Children below 15 are exempt from criminal liability and placed under Diversion Programs\n'
        '• Children 15–18 who acted with discernment may be subject to diversion or court proceedings\n'
        '• Emphasizes rehabilitation over punishment; CICL are placed in youth detention homes, not regular jails\n'
        '• Barangays play a role through the Barangay Council for the Protection of Children (BCPC)\n\n'
        'Penalties:\n'
        'No imprisonment for CICL; intervention and rehabilitation programs are prioritized.\n\n'
        '⚠️ This is general legal information only and does not constitute legal advice. Consult a licensed Philippine attorney for case-specific guidance.',
  ),

  // ── RA 10173 — Data Privacy ───────────────────────────────────────────────
  (
    ['10173', 'data privacy', 'personal data', 'privacy act', 'data protection'],
    '📋 RA 10173 — Data Privacy Act of 2012\n\n'
        'Purpose:\n'
        'Protects individual personal information in information and communications systems '
        'in government and the private sector.\n\n'
        'Key Provisions:\n'
        '• All personal data must be collected for a specific, legitimate purpose and with the consent of the data subject\n'
        '• Data subjects have the right to access, correct, and object to the processing of their personal data\n'
        '• Organizations must implement reasonable and appropriate security measures\n'
        '• The National Privacy Commission (NPC) enforces the law\n'
        '• Sensitive personal information (e.g., health, religion, political beliefs) has stricter protection\n\n'
        'Penalties:\n'
        'Imprisonment of 1–6 years and fines ranging from ₱500,000 to ₱4,000,000 depending on the violation.\n\n'
        '⚠️ This is general legal information only and does not constitute legal advice. Consult a licensed Philippine attorney for case-specific guidance.',
  ),

  // ── Katarungang Pambarangay process ───────────────────────────────────────
  (
    ['katarungang', 'pambarangay', 'barangay conciliation', 'barangay mediation', 'lupon tagapamayapa'],
    '⚖️ Katarungang Pambarangay (KP) Process\n\n'
        'The KP system under RA 7160 requires most disputes between residents of the same barangay '
        'to be brought to the barangay first before going to court.\n\n'
        'Steps:\n'
        '1. Filing — Complainant files a complaint with the Lupon Secretary\n'
        '2. Summons — Respondent is summoned within 2 days; hearing is set within 3 days\n'
        '3. Mediation — Lupon Chairman mediates for up to 15 days\n'
        '4. Conciliation Panel (Pangkat) — If mediation fails, a Pangkat of 3 Lupon members is formed within 3 days\n'
        '5. Pangkat Hearing — Pangkat has 15 days (extendable by 15 more) to settle the dispute\n'
        '6. Settlement or Certificate to File Action — If settled, an amicable settlement is signed. '
        'If not, a Certificate to File Action (CFA) is issued allowing court filing.\n\n'
        '⚠️ This is general legal information only and does not constitute legal advice. Consult a licensed Philippine attorney for case-specific guidance.',
  ),

  // ── Filing a complaint ────────────────────────────────────────────────────
  (
    ['file', 'complaint', 'reklamo', 'paano mag-reklamo', 'how to file'],
    '📝 How to File a Complaint at the Barangay\n\n'
        '1. Go to your barangay hall and look for the Lupon Secretary\n'
        '2. Fill out a written complaint form describing the dispute\n'
        '3. The Lupon Secretary will issue a summons to the respondent\n'
        '4. Attend the scheduled mediation hearing\n'
        '5. If no settlement is reached, you will receive a Certificate to File Action (CFA) '
        'to bring your case to court\n\n'
        'Note: Barangay conciliation is mandatory for disputes between residents of the same '
        'city/municipality before filing in court.\n\n'
        '⚠️ This is general legal information only and does not constitute legal advice. Consult a licensed Philippine attorney for case-specific guidance.',
  ),

  // ── Protection Order ──────────────────────────────────────────────────────
  (
    ['protection order', 'bpo', 'tpo', 'ppo', 'protective order'],
    '🛡️ Protection Orders in the Philippines\n\n'
        'Under RA 9262, victims of violence can apply for:\n\n'
        '1. Barangay Protection Order (BPO)\n'
        '   • Issued by the Punong Barangay\n'
        '   • Effective for 15 days\n'
        '   • Prohibits the respondent from committing further acts of violence\n\n'
        '2. Temporary Protection Order (TPO)\n'
        '   • Issued by a Family Court\n'
        '   • Effective for 30 days (extendable)\n\n'
        '3. Permanent Protection Order (PPO)\n'
        '   • Issued after notice and hearing by the court\n'
        '   • Does not expire unless lifted by the court\n\n'
        'To apply for a BPO, go to your barangay hall and inform the Punong Barangay about your situation.\n\n'
        '⚠️ This is general legal information only and does not constitute legal advice. Consult a licensed Philippine attorney for case-specific guidance.',
  ),

  // ── Estafa / Scam ─────────────────────────────────────────────────────────
  (
    ['estafa', 'scam', 'fraud', 'swindling', 'nanlinlang'],
    '⚖️ Estafa (Swindling) under the Revised Penal Code (Art. 315)\n\n'
        'What is Estafa?\n'
        'It is a crime committed by deceiving another person to defraud them of money, property, or services.\n\n'
        'Common forms:\n'
        '• Issuing bouncing checks (also covered by BP 22)\n'
        '• Misappropriating money or property entrusted to you\n'
        '• Using false pretenses or fraudulent acts\n\n'
        'Penalties depending on the amount involved:\n'
        '• Below ₱40,000 — Arresto Mayor (1–6 months)\n'
        '• ₱40,000–₱1.2M — Prision Correccional (6 months–6 years)\n'
        '• Above ₱1.2M — Prision Mayor (6–12 years) or Reclusion Temporal\n\n'
        'You may file a complaint at the barangay first if the respondent is a co-resident, '
        'otherwise directly with the Prosecutor\'s Office.\n\n'
        '⚠️ This is general legal information only and does not constitute legal advice. Consult a licensed Philippine attorney for case-specific guidance.',
  ),

  // ── Thank you ─────────────────────────────────────────────────────────────
  (
    ['thank', 'thanks', 'salamat', 'maraming salamat'],
    'You\'re welcome! 😊 If you have more questions about Philippine law or the barangay justice process, feel free to ask anytime.',
  ),
];

/// Fallback reply when no keyword is matched.
const String _fallback =
    'I\'m sorry, I\'m not sure about that topic. 🤔\n\n'
    'I can help you with:\n'
    '• Katarungang Pambarangay — barangay dispute resolution process\n'
    '• RA 9262 — Violence Against Women and Children (VAWC)\n'
    '• RA 7160 — Local Government Code\n'
    '• RA 7610 — Child Abuse Protection\n'
    '• RA 9344 — Juvenile Justice\n'
    '• RA 10173 — Data Privacy Act\n'
    '• Protection Orders (BPO, TPO, PPO)\n'
    '• How to file a barangay complaint\n\n'
    'Please try rephrasing your question or choose one of the quick prompts above.\n\n'
    '⚠️ This is general legal information only and does not constitute legal advice. Consult a licensed Philippine attorney for case-specific guidance.';

/// Ezu chatbot service — returns hardcoded Philippine legal information.
/// No API key or internet connection required.
class EzuGeminiService {
  /// Sends [userMessage] and returns a matching hardcoded response.
  Future<String> send(String userMessage) async {
    final lower = userMessage.toLowerCase();

    // Find the response first so we can base the delay on its length.
    String response = _fallback;
    for (final (keywords, candidate) in _ezuRules) {
      if (keywords.any((kw) => lower.contains(kw))) {
        response = candidate;
        break;
      }
    }

    // Dynamic "thinking" delay: 800 ms base + 18 ms per character, max 3 200 ms.
    // Longer answers feel like Ezu genuinely took time to compose them.
    final delayMs = (800 + response.length * 18).clamp(800, 3200);
    await Future<void>.delayed(Duration(milliseconds: delayMs));

    return response;
  }

  /// Resets the conversation (no-op for hardcoded service).
  void resetConversation() {}
}

final ezuGeminiServiceProvider = Provider<EzuGeminiService>(
  (_) => EzuGeminiService(),
);
