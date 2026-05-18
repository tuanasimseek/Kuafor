using System.Net;
using System.Net.Mail;

namespace KuaforApi.Services;

public class EmailService
{
    private readonly IConfiguration _configuration;

    public EmailService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public bool IsConfigured =>
        !string.IsNullOrWhiteSpace(Get("Smtp__Host")) &&
        !string.IsNullOrWhiteSpace(Get("Smtp__Username")) &&
        !string.IsNullOrWhiteSpace(Get("Smtp__Password"));

    public async Task SendPasswordResetAsync(string toEmail, string fullName)
    {
        if (!IsConfigured)
            throw new InvalidOperationException("SMTP ayarlari tanimli degil.");

        var host = Get("Smtp__Host")!;
        var port = int.TryParse(Get("Smtp__Port"), out var parsedPort) ? parsedPort : 587;
        var username = Get("Smtp__Username")!;
        var password = Get("Smtp__Password")!;
        var from = Get("Smtp__From") ?? username;

        using var client = new SmtpClient(host, port)
        {
            EnableSsl = true,
            Credentials = new NetworkCredential(username, password)
        };

        using var message = new MailMessage(from, toEmail)
        {
            Subject = "Kuafor uygulamasi sifre sifirlama",
            Body = $"Merhaba {fullName},\n\nSifre sifirlama talebiniz alindi. Demo surumde yeni sifre icin uygulama yoneticisiyle iletisime gecebilirsiniz.\n\nKuafor Randevu Sistemi"
        };

        await client.SendMailAsync(message);
    }

    private string? Get(string key)
    {
        return Environment.GetEnvironmentVariable(key) ?? _configuration[key.Replace("__", ":")];
    }
}
