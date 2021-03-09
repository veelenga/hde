function initializeSampleData() {
  let sampleUrls = [
    "https://www.analyticsvidhya.com/blog/2019/06/comprehensive-guide-text-summarization-using-deep-learning-python/",
    "https://towardsdatascience.com/text-summarization-using-deep-learning-6e379ed2e89c/",
    "https://machinelearningmastery.com/gentle-introduction-text-summarization/",
    "https://www.sciencedirect.com/science/article/pii/S1319157819301259/",
    "https://github.com/mbadry1/DeepLearning.ai-Summary/",
    "https://www.cnn.com/2020/03/12/opinions/oval-office-coronavirus-speech-trumps-worst-bergen/index.html",
    "https://www.cnn.com/2020/03/12/opinions/oval-office-coronavirus-speech-trumps-worst-bergen/index.html",
    "https://www.caranddriver.com/reviews/a21786823/2019-audi-q8-first-drive-review/",
    "https://www.topgear.com/car-reviews/audi/q8/",
    "https://www.youtube.com/watch?v=mii6NydPiqI/",
    "https://gardenerspath.com/how-to/beginners/first-vegetable-garden/",
    "https://lifehacker.com/the-seven-easiest-vegetables-to-grow-for-beginner-garde-1562176780",
    "https://www.gardeningknowhow.com/edible/vegetables/vgen/vegetable-gardening-for-beginners.htm"
  ];

  let text = sampleUrls.join('\n\n');
  document.getElementById('input-textarea').value = text;
}

window.addEventListener('load', () => initializeSampleData())
