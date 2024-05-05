from abc import ABC, abstractmethod

class BaseDetector(ABC):
    @abstractmethod
    def load_model(self):
        pass

    @abstractmethod
    def run(self, image_tensor):
        pass
