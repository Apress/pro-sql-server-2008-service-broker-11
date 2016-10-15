using System;
using System.Collections.Generic;
using System.Text;

namespace ConsoleApplication1
{
    class Program
    {
        static void Main(string[] args)
        {
            byte[] bytes = System.Convert.FromBase64String("PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz48c29hcDpFbnZlbG9wZSB4bWxuczpzb2FwPSJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy9zb2FwL2VudmVsb3BlLyIgeG1sbnM6eHNpPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYS1pbnN0YW5jZSIgeG1sbnM6eHNkPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYSI+PHNvYXA6Qm9keT48SGVsbG9Xb3JsZFJlc3BvbnNlIHhtbG5zPSJodHRwOi8vdGVtcHVyaS5vcmcvIj48SGVsbG9Xb3JsZFJlc3VsdD5IZWxsbyBXb3JsZDwvSGVsbG9Xb3JsZFJlc3VsdD48L0hlbGxvV29ybGRSZXNwb25zZT48L3NvYXA6Qm9keT48L3NvYXA6RW52ZWxvcGU+");
            ASCIIEncoding encoding = new ASCIIEncoding();

            Console.WriteLine(encoding.GetString(bytes));


            string request = "<?xml version=\"1.0\" encoding=\"utf-8\"?>";
            request += "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">";
            request += "<soap:Body>";
            request += "<HelloWorld xmlns=\"http://tempuri.org/\" />";
            request += "</soap:Body>";
            request += "</soap:Envelope>";


            string encoded = System.Convert.ToBase64String(encoding.GetBytes(request));
            Console.WriteLine(encoded);

            Console.WriteLine("Done");
            Console.ReadLine();
        }
    }
}
