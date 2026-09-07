import 'package:cakeu/core/errors/exceptions.dart';

/// Exception thrown when AI fails to parse or analyze receipt photo.
class ReceiptScanException extends AppException {
  const ReceiptScanException([
    super.message = 'Foto struk tidak terbaca dengan jelas. Pastikan foto tegak, fokus, dan tidak terpotong.',
    String? code,
  ]) : super(code: code ?? 'RECEIPT_UNREADABLE');
}

/// Exception thrown when AI Rate Limit / Quota is exceeded.
class AiRateLimitException extends AppException {
  const AiRateLimitException([
    super.message = 'Layanan AI sedang sibuk. Silakan tunggu beberapa detik lalu coba lagi.',
    String? code,
  ]) : super(code: code ?? 'AI_RATE_LIMIT');
}

/// Exception thrown when AI returns invalid JSON or unparseable structure.
class AiParsingException extends AppException {
  const AiParsingException([
    super.message = 'Format respons AI tidak valid.',
    String? code,
  ]) : super(code: code ?? 'AI_PARSING_ERROR');
}

/// Exception thrown when Edge Function fails to communicate with OpenAI.
class OpenAiServiceException extends AppException {
  const OpenAiServiceException(
    super.message, {
    super.code = 'OPENAI_SERVICE_ERROR',
    super.details,
  });
}
