using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using OrleansBasics.Models;

namespace OrleansPoc.Sevices
{
    public static class SearchAddressClient
    {
        internal static string _urlIndex { get; } = "https://www.post.japanpost.jp/zipcode/index.html";
        internal static string _urlBase { get; } = "https://www.post.japanpost.jp/cgi-zip/";
        internal static string _urlZipSearch { get; } = $"{_urlBase}zipcode.php";
        internal static string _urlAddressSearch { get; } = $"{_urlZipSearch}?zip={{0}}";

        static HttpClient? _httpClient { get; set; }
        internal static HttpClient HttpClient { get => _httpClient ?? (_httpClient = new HttpClient()); }

        static Regex _regDataRows { get; } = new Regex("<tr>(.|\\n)*? class=\"data\"(.|\\n)*?</tr>");
        internal static string[] GetDataRows(string html) => _regDataRows.Matches(html)?.OfType<Match>().Select(m => m.Value).ToArray() ?? Array.Empty<string>();


        public static void Init(HttpClient httpClient) => _httpClient = httpClient;
        public static async Task<Address[]> ZipToAddress(string code) => await Sevices.ZipToAddress.Search(code);
        public static async Task<Address[]> AddressToZip(string pref, string address) => await Sevices.AddressToZip.Search(pref, address);
        public static async Task<Prefecture[]> Prefectures() => await Sevices.Prefectures.GetPrefectures();
    }

    internal static class ZipToAddress
    {
        public static async Task<Address[]> Search(string code)
        {
            var searchurl = string.Format(SearchAddressClient._urlAddressSearch, System.Net.WebUtility.UrlEncode(code));
            var html = await SearchAddressClient.HttpClient.GetStringAsync(searchurl);
            var addressList = GetAddressList(html).ToArray();
            return addressList;
        }

        static IEnumerable<Address> GetAddressList(string html)
        {
            var addressHtmlList = SearchAddressClient.GetDataRows(html);
            foreach (var addressHtml in addressHtmlList)
                yield return GetAddress(addressHtml);
        }

        static Address GetAddress(string html)
        {
            var values = GetDataElements(html).Select(elm => GetText(elm)).ToArray();
            var kana = GetKana(html);
            var address = new Address(values, kana);
            return address;
        }

        static string GetKana(string html)
        {
            var elm = GetKanaElement(html);
            var kana = GetText(elm);
            return kana;
        }

        static Regex _regDataElements { get; } = new Regex(" class=\"data\"(.|\\n)*?>[^>\\s]+<");
        static string[] GetDataElements(string html) => _regDataElements.Matches(html)?.OfType<Match>().Select(m => m.Value).ToArray() ?? Array.Empty<string>();

        static Regex _regGetText { get; } = new Regex(">[^>\\s]+<");
        static string GetText(string html) => _regGetText.Match(html)?.Value.Replace("<", "").Replace(">", "").Replace("&nbsp;", "") ?? "";

        static Regex _regKanaElement { get; } = new Regex(" class=\"comment\"(.|\\n)*?>[^>\\s]+<");
        static string GetKanaElement(string html) => _regKanaElement.Match(html)?.Value ?? "";
    }

    internal static class AddressToZip
    {
        public static async Task<Address[]> Search(string pref, string address)
        {
            var parameters = new FormUrlEncodedContent(new Dictionary<string, string>
            {
                {"pref", pref},
                {"addr", address}
            });
            var responce = await SearchAddressClient.HttpClient.PostAsync(SearchAddressClient._urlZipSearch, parameters);
            var html = await responce.Content.ReadAsStringAsync();
            var zipList = await GetZipList(html);
            return zipList;
        }

        static async Task<Address[]> GetZipList(string html)
        {
            var hrefs = SearchAddressClient.GetDataRows(html).Select(data => GetHref(data)).ToArray();
            var addresss = await Task.WhenAll(hrefs.Select(async href => await GetZipAndAddress(href)).AsParallel());
            return addresss;
        }

        static async Task<Address> GetZipAndAddress(string href)
        {
            var url = $"{SearchAddressClient._urlBase}{href}";
            var html = await SearchAddressClient.HttpClient.GetStringAsync(url);
            var zip = GetZip(html);
            var address = GetAddresss(zip, html);
            return address;
        }

        static Regex _regZip { get; } = new Regex("<span class=\"zip-code\">(.|\\n)*?</span>");
        static string GetZip(string html) => GetText2(_regZip.Match(html)?.Value.Replace("〒", ""));

        static Regex _regGetText2 { get; } = new Regex(">([^>]|\\n)*?</");
        static string GetText2(string html) => _regGetText2.Match(html)?.Value.Replace("</", "").Replace(">", "").Trim() ?? "";

        static Regex _regAddress { get; } = new Regex(" class=\"data\" (.|\\n)*?</div>");
        static Address GetAddresss(string zip, string html)
        {
            var addressArea = _regAddress.Match(html)?.Value ?? "";
            var valuesElement = _regGetText2.Matches(addressArea).OfType<Match>().Select(m => m.Value).ToArray();
            var values = valuesElement.Select(m => GetText2(m)).Where(v => !string.IsNullOrWhiteSpace(v)).ToArray();

            return new Address(zip, values);
        }
        static Regex _regHref { get; } = new Regex(" href=\".+?\"");
        static string GetHref(string html) => _regHref.Match(html)?.Value.Replace(" href=", "").Replace("\"", "") ?? "";
    }

    public static class Prefectures
    {
        static Prefecture[] _all { get; } = new Prefecture[] {
            new Prefecture("1", "北海道"),
                            new Prefecture("2", "青森県"),
                            new Prefecture("3", "岩手県"),
                            new Prefecture("4", "宮城県"),
                            new Prefecture("5", "秋田県"),
                            new Prefecture("6", "山形県"),
                            new Prefecture("7", "福島県"),
                            new Prefecture("8", "茨城県"),
                            new Prefecture("9", "栃木県"),
                            new Prefecture("10", "群馬県"),
                            new Prefecture("11", "埼玉県"),
                            new Prefecture("12", "千葉県"),
                            new Prefecture("13", "東京都"),
                            new Prefecture("14", "神奈川県"),
                            new Prefecture("15", "新潟県"),
                            new Prefecture("16", "富山県"),
                            new Prefecture("17", "石川県"),
                            new Prefecture("18", "福井県"),
                            new Prefecture("19", "山梨県"),
                            new Prefecture("20", "長野県"),
                            new Prefecture("21", "岐阜県"),
                            new Prefecture("22", "静岡県"),
                            new Prefecture("23", "愛知県"),
                            new Prefecture("24", "三重県"),
                            new Prefecture("25", "滋賀県"),
                            new Prefecture("26", "京都府"),
                            new Prefecture("27", "大阪府"),
                            new Prefecture("28", "兵庫県"),
                            new Prefecture("29", "奈良県"),
                            new Prefecture("30", "和歌山県"),
                            new Prefecture("31", "鳥取県"),
                            new Prefecture("32", "島根県"),
                            new Prefecture("33", "岡山県"),
                            new Prefecture("34", "広島県"),
                            new Prefecture("35", "山口県"),
                            new Prefecture("36", "徳島県"),
                            new Prefecture("37", "香川県"),
                            new Prefecture("38", "愛媛県"),
                            new Prefecture("39", "高知県"),
                            new Prefecture("40", "福岡県"),
                            new Prefecture("41", "佐賀県"),
                            new Prefecture("42", "長崎県"),
                            new Prefecture("43", "熊本県"),
                            new Prefecture("44", "大分県"),
                            new Prefecture("45", "宮崎県"),
                            new Prefecture("46", "鹿児島県"),
                            new Prefecture("47", "沖縄県"),
        };
        public static IEnumerable<Prefecture> All() => _all.ToArray();
        public static async Task<Prefecture[]> GetPrefectures()
        {
            var url = SearchAddressClient._urlIndex;
            var html = await SearchAddressClient.HttpClient.GetStringAsync(url);
            var prefHtml = GetPref(html);
            var options = GetOptions(prefHtml);
            var prefectures = options?.Select(option =>
            {
                var value = GetValue(option);
                var name = GetName(option);
                return new Prefecture(value, name);
            }).ToArray() ?? Array.Empty<Prefecture>(); ;
            return prefectures;
        }

        static Regex _regPref { get; } = new Regex("<select name=\"pref\"(.|\\n)*?</select>");
        static Regex _regOption { get; } = new Regex("<option value=\".+?\">(.|\\n)+?</option>");
        static Regex _regValue { get; } = new Regex("\".+?\"");
        static Regex _regName { get; } = new Regex(">.+?<");
        static string GetPref(string html) => _regPref.Match(html)?.Value ?? "";
        static string[] GetOptions(string html) => _regOption.Matches(html)?.OfType<Match>().Select(m => m.Value).ToArray() ?? Array.Empty<string>();
        static string GetValue(string html) => _regValue.Match(html)?.Value.Replace("\"", "") ?? "";
        static string GetName(string html) => _regName.Match(html)?.Value.Replace(">", "").Replace("<", "") ?? "";
    }
}