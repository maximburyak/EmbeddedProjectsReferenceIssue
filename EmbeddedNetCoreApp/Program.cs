using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Server.Kestrel.Core;
using System;

namespace EmbeddedNetCoreApp
{
    class Program
    {
        private static IWebHostBuilder _webHostBuilder;

        static void Main(string[] args)
        {
            _webHostBuilder = new WebHostBuilder()
                                .CaptureStartupErrors(captureStartupErrors: true)
                                .UseKestrel(ConfigureKestrel)
                                .UseShutdownTimeout(TimeSpan.FromSeconds(1));



            void ConfigureKestrel(KestrelServerOptions options)
            {
            }
                Console.WriteLine("Hello World!");
        }
    }
}
