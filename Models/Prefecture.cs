namespace OrleansBasics.Models
{
    public struct Prefecture
    {
        public string Code { get; }
        public string Name { get; }

        public Prefecture(string code, string name)
        {
            Code = code;
            Name = name;
        }

        public override string ToString() => Name;

        public static Prefecture Empty => new Prefecture(string.Empty, string.Empty);
    }
}