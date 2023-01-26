namespace Grains.Status
{
    [Serializable]
    public class WriteLargeDataState
    {
        public WriteLargeDataState() { }
        public string LargeData { get; set; } = string.Empty;
    }
}

