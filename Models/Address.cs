using System.Linq;

namespace OrleansBasics.Models
{
    public struct Address
    {
        public string ZipCode { get; }
        public string Prefecture { get; }
        public string City { get; }
        public string Machi { get; }
        public string Kana { get; }

        public Address(string[] values)
        {
            ZipCode = values?.FirstOrDefault();
            Prefecture = values?.Skip(1).FirstOrDefault();
            City = values?.Skip(2).FirstOrDefault();
            Machi = values?.Skip(3).FirstOrDefault();
            Kana = values?.Skip(4).FirstOrDefault();
        }
        public Address(string zip, string[] values) : this(new string[] { zip }.Union(values).ToArray()) {; }
        public Address(string[] values, string kana) : this(values.Take(4).Union(new[] { kana }).ToArray()) {; }

        public override string ToString()
        {
            return $"{ZipCode} {Prefecture} {City} {Machi} {Kana}";
        }
    }
}